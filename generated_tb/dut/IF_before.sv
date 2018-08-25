/*
* @info Intruction Fetch Stage
* @info Sub Modules: Predictor.sv, icache.sv
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief The first stage of the processor. It contains the predictor and the icache
*
* @param PC_BITS       : # of PC Address Bits
* @param INSTR_BITS    : # of Fetched Instruction Bits
*/
`include "structs.sv"
module IF #(
    parameter int PC_BITS          = 32  ,
    parameter int INSTR_BITS       = 32  ,
    parameter int FETCH_WIDTH      = 64  ,
    parameter int PACKET_SIZE      = 64  ,
    parameter int RAS_DEPTH        = 8   ,
    parameter int GSH_HISTORY_BITS = 2   ,
    parameter int GSH_SIZE         = 256 ,
    parameter int BTB_SIZE         = 256)
    //Input List
    (
    input  logic                      clk,
    input  logic                      rst_n,
    //Output Interface
    output logic[2*PACKET_SIZE-1:0]   data_out,
    output logic                      valid_o,
    input  logic                      ready_in,
    //Predictor Update Interface
    input  predictor_update           pr_update,
    //Restart Interface
    input  logic                      is_branch,
    input  logic                      invalid_instruction,
    input  logic                      invalid_prediction,
    input  logic                      is_return_in,
    input  logic                      is_jumpl,
    input  logic[PC_BITS-1:0]         old_PC,
    //Flush Interface
    input  logic                      must_flush,
    input  logic[PC_BITS-1:0]         correct_address,
    //ICache Interface
    output logic    [PC_BITS-1:0]     current_PC,
    input  logic                      Hit_cache,
    input  logic                      Miss,
    input  logic                      partial_access,
    input  logic            [1:0]     partial_type,
    input  logic  [FETCH_WIDTH-1:0]   fetched_data
);

    typedef enum logic[1:0] {NONE, LOW, HIGH} override_priority;
    logic             [    FETCH_WIDTH-1:0] instruction_out    ;
    logic             [        PC_BITS-1:0] next_PC            ;
    logic             [        PC_BITS-1:0] next_PC_2          ;
    logic             [        PC_BITS-1:0] PC_Orig            ;
    logic             [        PC_BITS-1:0] Target_PC          ;
    logic             [        PC_BITS-1:0] saved_PC           ;
    logic             [        PC_BITS-1:0] next_PC_saved      ;
    logic             [        PC_BITS-1:0] old_PC_saved       ;
    logic             [3*FETCH_WIDTH/4-1:0] partial_saved_instr;
    logic             [                1:0] partial_type_saved ;
    override_priority                       over_priority      ;
    logic                                   Hit                ;
    logic                                   new_entry          ;
    logic                                   is_Taken           ;
    logic                                   is_return          ;
    logic                                   is_return_fsm      ;
    logic                                   taken_branch_saved ;
    logic                                   taken_branch_1     ;
    logic                                   half_access        ;
    logic                                   taken_branch_2     ;

    // assign data_out = half_access? {old_PC_saved, instruction_out} : {current_PC, instruction_out};     // ADD PC 1 & 2
    // assign data_out              = half_access? {current_PC,old_PC_saved, instruction_out} : {current_PC+4,current_PC, instruction_out};
    fetched_packet packet_a, packet_b;
    assign data_out              = {packet_b,packet_a};
    assign packet_a.pc           = half_access? old_PC_saved : current_PC;
    assign packet_a.data         = instruction_out[INSTR_BITS-1:0];
    assign packet_a.taken_branch = half_access ? taken_branch_saved : taken_branch_1;
    assign packet_b.pc           = half_access? current_PC : current_PC+4;
    assign packet_b.data         = instruction_out[2*INSTR_BITS-1:INSTR_BITS];
    assign packet_b.taken_branch = taken_branch_2;
    // assign valid_o  = Hit & (over_priority==NONE) & ~(is_return_in | is_return_fsm) & ~invalid_prediction & ~must_flush & ~invalid_instruction & ~taken_branch_1;
    assign valid_o = half_access ?  Hit & (over_priority==NONE) & ~(is_return_in | is_return_fsm) & ~invalid_prediction & ~must_flush & ~invalid_instruction :
                                    Hit & (over_priority==NONE) & ~(is_return_in | is_return_fsm) & ~invalid_prediction & ~must_flush & ~invalid_instruction & ~taken_branch_1;

    //Intermidiate Signals
    assign new_entry = pr_update.valid_jump;
    assign PC_Orig   = pr_update.orig_pc;
    assign Target_PC = pr_update.jump_address;
    assign is_Taken  = pr_update.jump_taken;

    assign is_return = (is_return_in | is_return_fsm) & Hit;      //- Might need to use FSM for is_return_in if it's not constantly supplied from the IF/ID
    always_ff @(posedge clk or negedge rst_n) begin : returnFSM
        if(!rst_n) begin
            is_return_fsm <= 0;
        end else begin
            if(!is_return_fsm && is_return_in && !Hit) begin
                is_return_fsm <= ~must_flush;
            end else if(is_return_fsm && Hit) begin
                is_return_fsm <= 0;
            end
        end
    end

    Predictor #(
        .PC_BITS         (PC_BITS         ),
        .RAS_DEPTH       (RAS_DEPTH       ),
        .GSH_HISTORY_BITS(GSH_HISTORY_BITS),
        .GSH_SIZE        (GSH_SIZE        ),
        .BTB_SIZE        (BTB_SIZE        ),
        .FETCH_WIDTH     (FETCH_WIDTH     )
    ) Predictor (
        .clk            (clk                 ),
        .rst_n          (rst_n               ),
        
        .must_flush     (must_flush          ),
        .is_branch      (is_branch           ),
        .branch_resolved(pr_update.valid_jump),
        
        .new_entry      (new_entry           ),
        .PC_Orig        (PC_Orig             ),
        .Target_PC      (Target_PC           ),
        .is_Taken       (is_Taken            ),
        
        .is_return      (is_return           ),
        .is_jumpl       (is_jumpl            ),
        .invalidate     (invalid_prediction  ),
        .old_PC         (old_PC              ),
        
        .PC_in          (current_PC          ),
        .taken_branch_a (taken_branch_1      ),
        .next_PC_a      (next_PC             ),
        .taken_branch_b (taken_branch_2      ),
        .next_PC_b      (next_PC_2           )
    );

    // Create the Output
    // assign instruction_out = half_access ? {fetched_data[FETCH_WIDTH/2-1:0],partial_saved_instr} : fetched_data;
    assign Hit = Hit_cache & ~partial_access;
    always_comb begin : DataOut
    	if(half_access) begin
    		if(partial_type_saved == 2'b11) begin
    			instruction_out = {fetched_data[FETCH_WIDTH/4-1:0],partial_saved_instr};
    		end else if(partial_type_saved == 2'b10) begin
    			instruction_out = {fetched_data[FETCH_WIDTH/2-1:0],partial_saved_instr[FETCH_WIDTH/2-1:0]};
    		end else begin
    			instruction_out = {fetched_data[3*FETCH_WIDTH/4-1:0],partial_saved_instr};
    		end
    	end else begin
    		instruction_out = fetched_data;
    	end
    end

    // Two-Cycle Fetch FSM
    always_ff @(posedge clk or negedge rst_n) begin : isHalf
        if(!rst_n) begin
            half_access <= 0;
        end else begin
            if(partial_access && !half_access && Hit_cache) begin
                half_access <= ~(invalid_prediction | invalid_instruction | is_return_in | must_flush | over_priority!=NONE);
            end else if(taken_branch_1 && !half_access && Hit_cache) begin
                half_access <= ~((over_priority!=NONE) | invalid_prediction | invalid_instruction | is_return_in | must_flush);
            end else if(half_access && Hit && ready_in) begin
                half_access <= 0;
            end else if(half_access && Hit_cache) begin
                half_access <= ~((over_priority!=NONE) | invalid_prediction | invalid_instruction | is_return_in | must_flush);
            end
        end
    end
    // Half Instruction Management
    always_ff @(posedge clk) begin : HalfInstr
        if(!half_access && Hit_cache) begin
            if(partial_access && partial_type == 2'b01) begin
                partial_saved_instr <= {{48{1'b0}},fetched_data[FETCH_WIDTH/4-1:0]};
                old_PC_saved        <= current_PC;
                taken_branch_saved  <= 1'b0;
                next_PC_saved       <= current_PC+8;
                partial_type_saved  <= partial_type;
            end else if(taken_branch_1) begin
                partial_saved_instr <= {{32{1'b0}},fetched_data[FETCH_WIDTH/2-1:0]};
                old_PC_saved        <= current_PC;
                taken_branch_saved  <= taken_branch_1;
                next_PC_saved       <= next_PC+4;
                partial_type_saved  <= 2'b10;
            end else if(partial_access && partial_type == 2'b10) begin
                partial_saved_instr <= {{32{1'b0}},fetched_data[FETCH_WIDTH/2-1:0]};
                old_PC_saved        <= current_PC;
                taken_branch_saved  <= 1'b0;
                next_PC_saved       <= current_PC+8;
                partial_type_saved  <= partial_type;
            end else if(partial_access && partial_type == 2'b11) begin
                partial_saved_instr <= fetched_data[3*FETCH_WIDTH/4-1:0];
                old_PC_saved        <= current_PC;
                taken_branch_saved  <= 1'b0;
                next_PC_saved       <= current_PC+8;
                partial_type_saved  <= partial_type;
            end
        end
    end
    // PC Address Management
    always_ff @(posedge clk or negedge rst_n) begin : PCManagement
        if(!rst_n) begin
            current_PC <= 0;
        end else begin
            // Normal Operation
            if(Hit_cache) begin
                if(over_priority==HIGH) begin
                    current_PC <= saved_PC;
                end else if(must_flush) begin
                    current_PC <= correct_address;
                end else if(over_priority==LOW) begin
                    current_PC <= saved_PC;
                end else if(invalid_prediction) begin
                    current_PC <= old_PC;
                end else if (invalid_instruction) begin
                    current_PC <= old_PC;
                end else if (is_return_in) begin
                    current_PC <= next_PC; 
                end else if(partial_access && partial_type== 1) begin
                    current_PC <= current_PC +2;
                end else if(taken_branch_1) begin
                    current_PC <= next_PC;
                end else if (partial_access && partial_type== 2) begin
                    current_PC <= current_PC +4;
                end else if (partial_access && partial_type== 3) begin
                    current_PC <= current_PC +6;
                end else if (ready_in && !half_access) begin
                    // current_PC <= next_PC;
                    current_PC <= taken_branch_2 ? next_PC_2 : next_PC;
                end else if (ready_in && half_access) begin
                    // current_PC <= next_PC_saved;
                    current_PC <= taken_branch_2 ? next_PC_2 : next_PC_saved;
                end
            end 
        end
    end
    //Override FSM used to indicate a redirection must happen after cache unblocks
        //Flushing takes priority due to being an older instruction
    always_ff @(posedge clk or negedge rst_n) begin : overrideManagement
        if(!rst_n) begin
            over_priority <= NONE;
        end else begin
            if(must_flush && over_priority!=HIGH && !Hit_cache) begin
                over_priority <= HIGH;
                saved_PC      <= correct_address;
            end else if(invalid_prediction && over_priority==NONE && !Hit_cache) begin
                over_priority <= LOW;
                saved_PC      <= old_PC;
            end else if(invalid_instruction && over_priority==NONE && !Hit_cache) begin
                over_priority <= LOW;
                saved_PC      <= old_PC;
            end else if(is_return_in && over_priority==NONE && !Hit_cache) begin
                over_priority <= LOW;
                saved_PC      <= old_PC;
            end else if(Hit_cache) begin
                over_priority <= NONE;
            end
        end
    end

    //=================================================================================
    //BENCHMARKING COUNTER SECTION
    logic [63:0] redir_realign, redir_prediction, redir_return, redirections, flushes, missed_branch;
    logic        redirect, alignment_redirect, fnct_return_redirect, flush_redirect;

    assign fnct_return_redirect = Hit & ~valid_o & invalid_instruction;
    assign alignment_redirect   = Hit & ~valid_o & invalid_instruction;
    assign redirect             = Hit & ~valid_o;
    assign flush_redirect       = Hit & ~valid_o & must_flush;

    always_ff @(posedge clk or negedge rst_n) begin : ReDir
        if(!rst_n) begin
            redir_realign    <= 0;
            redir_prediction <= 0;
            redir_return     <= 0;
            flushes          <= 0;
            redirections     <= 0;
            missed_branch    <= 0;
        end else begin
            if(alignment_redirect) begin
                redir_realign <= redir_realign +1;
            end
            if(invalid_prediction) begin
                redir_prediction <= redir_prediction +1;
            end
            if(fnct_return_redirect) begin
                redir_return <= redir_return +1;
            end
            if(flush_redirect) begin
                flushes <= flushes +1;
            end
            if(redirect) begin
                redirections <= redirections +1;
            end
            if(taken_branch_2 && valid_o && ready_in && !half_access) begin
                missed_branch <= missed_branch +1;
            end
        end
    end

assert property (@(posedge clk) disable iff(!rst_n) partial_access |-> 1'b1) else $warning("Half Access Detected, two cycle fetch needed");
assert property (@(posedge clk) disable iff(!rst_n) must_flush |-> !valid_o) else $error("IF - Error, wrong instruction injected in the pipeline");
assert property (@(posedge clk) disable iff(!rst_n) partial_access |-> (partial_type==2'b10)) else $error("IF - Dummy, wrong partial access type");

logic [INSTR_BITS-1:0] fetced_data_0, fetced_data_1;
assign fetced_data_0 = fetched_data[INSTR_BITS-1:0];
assign fetced_data_1 = fetched_data[2*INSTR_BITS-1:INSTR_BITS];

endmodule