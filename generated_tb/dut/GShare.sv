/*
* @info GShare Predictor
* @info Top Modules: Predictor.sv
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief A direction predictor, using the global history.
*
* @param PC_BITS 	   : # of PC Address Bits
* @param SEL_BITS 	   : # of Selector bits used from PC
* @param HISTORY_BITS : # of bits for Global History
* @param SIZE 		   : # of addressable entries (lines) in the array
*/
module GShare #(PC_BITS=32,HISTORY_BITS=2,SIZE=1024) (
	input  logic               clk           ,
	input  logic               rst_n         ,
	//Access Interface
	input  logic [PC_BITS-1:0] PC_in_a       ,
	input  logic [PC_BITS-1:0] PC_in_b       ,
	output logic               is_Taken_out_a,
	output logic               is_Taken_out_b,
	//Update Interface
	input  logic               Wr_En         ,
	input  logic [PC_BITS-1:0] Orig_PC       ,
	input  logic               is_Taken
);
	localparam SEL_BITS = $clog2(SIZE);
	// #Internal Signals#
	logic [    SEL_BITS-1 : 0] line_selector_a, line_selector_b;
	logic [HISTORY_BITS-1 : 0] counter_selector_a, counter_selector_b;
	logic [HISTORY_BITS-1 : 0] gl_history         ;
	logic [             1 : 0] retrieved_counter_a, retrieved_counter_b, old_counter, final_value;
	logic [             7 : 0] retrieved_data_a, retrieved_data_b, write_retrieved_data, new_counter_vector;

	logic [    SEL_BITS-1 : 0] write_line_selector   ;
	logic [HISTORY_BITS-1 : 0] write_counter_selector;
	logic [HISTORY_BITS +1: 0] starting_bit_a, starting_bit_b, write_counter_stating_bit;
	logic [2:0][SEL_BITS-1 : 0]read_addresses;
	logic [2:0][7 :0] 		   data_out;

	localparam int GS_SIZE = 8*SIZE + $bits(gl_history);
	//create the Line Selector from the PC_in_a bits k-2
	assign line_selector_a = PC_in_a[SEL_BITS : 1];
	assign line_selector_b = PC_in_b[SEL_BITS : 1];
	initial begin

		forever begin 
			if(PC_in_a==228) begin
				$display("[ DUT  ] @ %0t ps read counter, pc=%0d, line=%0d, cnt_id=%0d, is_taken=%b, cnt_value=%0d, history=%0d",$time(),PC_in_a,line_selector_a,counter_selector_a,is_Taken_out_a,retrieved_counter_a,gl_history);
			end
			if(PC_in_b==228) begin
				$display("[ DUT  ] @ %0t ps read counter, pc=%0d, line=%0d, cnt_id=%0d, is_taken=%b, cnt_value=%0d, history=%0d",$time(),PC_in_b,line_selector_b,counter_selector_b,is_Taken_out_b,retrieved_counter_b,gl_history);
			end

			if(Wr_En&(Orig_PC==672)) begin
				$display("[ DUT  ] @ %0t ps updt counter, pc=%0d, line=%0d, cnt_id=%0d, is_taken=%b",$time(),Orig_PC,write_line_selector,write_counter_selector,is_Taken);
			end
			@(negedge clk);
		end
	end

	//create the Counter Selector (PC XOR global history)
	assign counter_selector_a = gl_history ^ PC_in_a[HISTORY_BITS : 1];
	assign counter_selector_b = gl_history ^ PC_in_b[HISTORY_BITS : 1];
	//Pick one of the Counters
	assign starting_bit_a      = counter_selector_a << 1;
	assign starting_bit_b      = counter_selector_b << 1;
	assign retrieved_counter_a = retrieved_data_a[starting_bit_a +: 2];
	assign retrieved_counter_b = retrieved_data_b[starting_bit_b +: 2];
	//MSB of counter is our output
	assign is_Taken_out_a = retrieved_counter_a[1];
	assign is_Taken_out_b = retrieved_counter_b[1];

	assign read_addresses[0] = line_selector_a;
	assign read_addresses[1] = line_selector_b;
	assign read_addresses[2] = write_line_selector;

	SRAM #(
		.SIZE      (SIZE),
		.DATA_WIDTH(8   ),
		.RD_PORTS  (3   ),
		.WR_PORTS  (1   ),
		.RESETABLE (1   )
	) SRAM (
		.clk          (clk                ),
		.rst_n        (rst_n              ),
		.Wr_En        (Wr_En              ),
		.read_address (read_addresses     ),
		.data_out     (data_out           ),
		.write_address(write_line_selector),
		.new_data     (new_counter_vector )
	);

	assign retrieved_data_a     = data_out[0];
	assign retrieved_data_b     = data_out[1];
	assign write_retrieved_data = data_out[2];

	assign write_line_selector       = Orig_PC[SEL_BITS : 1];
	assign write_counter_selector    = gl_history ^ Orig_PC[HISTORY_BITS : 1];
	assign write_counter_stating_bit = write_counter_selector << 1;
	//Get the old Counter Value
	assign old_counter = write_retrieved_data[write_counter_stating_bit +: 2];
	//Calculate the next Counter Value (Increment/Decrement)
	always_comb begin : NewValue
		if(is_Taken) begin
			if(old_counter<2'b11) begin
				final_value = old_counter+1;
			end else begin
				final_value = old_counter;
			end
		end else begin
			if(old_counter>2'b00) begin
				final_value = old_counter-1;
			end else begin
				final_value = old_counter;
			end
		end
	end
	//Create the vector to be written back
	always_comb begin : NewVector
		// Only one counter is modified
		new_counter_vector                               = write_retrieved_data;
		new_counter_vector[write_counter_stating_bit+:2] = final_value;
	end

	always_ff @(posedge clk or negedge rst_n) begin : UpdateGH
		//reset global history
		if(!rst_n) begin
			gl_history <= 2'b00;
		end else begin
			//Update Global History by sliding
			if(Wr_En) begin
				gl_history <= { is_Taken , gl_history[HISTORY_BITS-1:1] };
			end
		end
	end

endmodule