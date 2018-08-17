/*
 * @info Return Address Stack
 * @info Sub-Modules: fifo_flush.sv
 *
 * @author VLSI Lab, EE dept., Democritus University of Thrace
 *
 * @note Buffer only saves 31/32 bits of the PC -> Lower 1 bit not needed,
 *
 * @param PC_BITS : # of PC Bits (default 32 bits)
 * @param SIZE    : # of entries (lines) in the buffer
 */ 
module RAS #(PC_BITS=32,SIZE=32) (
    input  logic               clk            ,
    input  logic               rst_n          ,
    input  logic               must_flush     ,
    input  logic               is_branch      ,
    input  logic               branch_resolved,
    input  logic               Pop            ,
    input  logic               Push           ,
    input  logic [PC_BITS-1:0] new_entry      ,
    output logic [PC_BITS-1:0] PC_out         ,
    output logic               is_empty
);

	localparam CON_BITS = $clog2(SIZE);
    // #Internal Signals#
    //-2 to create the 31bits space instead of 32bits for the Address
    logic [SIZE-1:0][PC_BITS-2:0] Buffer;
    logic [CON_BITS-1 : 0] head, tail, data_pointer, checkpointed_TOS;
    logic [CON_BITS   : 0] checkpoint_pushed, checkpoint_out;
    logic [ PC_BITS-2 : 0] data_out         ;
    logic                  lastPush,  checkpoint_valid, checkpointed_lastPush;

    localparam int RAS_SIZE = $bits(Buffer) + 2*$bits(head) + 4*(CON_BITS+1);
	//Create the empty stat output
	assign is_empty = (head == tail) & ~lastPush;
	//extend t he stored 31 bits to 32 and output them
	assign data_pointer = head-1;
	assign data_out = Buffer[data_pointer];
	assign PC_out   = {data_out,1'b0};
	
    assign checkpoint_pushed = {head,lastPush};
    //Initialize the fifo for the TOS checkpointing
    fifo_overflow #(
        .DW     (CON_BITS+1),
        .DEPTH  (4))
    fifo_overflow  (
        .clk        (clk),
        .rst        (~rst_n),
        .flush      (must_flush),

        .push_data  (checkpoint_pushed),
        .push       (is_branch),

        .pop_data   (checkpoint_out),
        .valid      (checkpoint_valid),
        .pop        (branch_resolved & checkpoint_valid)
        );

    assign checkpointed_lastPush = checkpoint_out[0];
    assign checkpointed_TOS      = checkpoint_out[CON_BITS:1];
	always_ff @(posedge clk) begin : MemoryManagement
		if(Push) begin
			Buffer[head] <= new_entry[PC_BITS-1:1];
		end
	end

	always_ff @(posedge clk or negedge rst_n) begin : PointerManagement
		if(!rst_n) begin
			head     <= 0;
			tail     <= 0;
			lastPush <= 0;
		end else begin	
            if(must_flush && checkpoint_valid) begin
                //Restore Checkpoint
                head <= checkpointed_TOS;
                lastPush <= checkpointed_lastPush;
            end else if(Push) begin
                //Push new Values
				lastPush <= 1;													
				head     <= head + 1;			
				//Override the oldest value when Buffer Full	
				if(head==tail && lastPush) begin
					tail <= tail+1;					
				end
			end else if(Pop) begin	
                //Pop Values when not Empty			
				head <= head-1;
				lastPush <= 0;
			end		 
		end
	end

	//Can not Pop from an empty RAS
	assert property (@(posedge clk) disable iff(!rst_n) Pop |-> !is_empty) else $error("Pop from Empty RAS!!");

endmodule