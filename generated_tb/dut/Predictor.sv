/*
 * @info Predictor Top-Module
 * @info Sub Modules: RAS.sv  Gshare.sv, BTB.sv
 *
 * @author VLSI Lab, EE dept., Democritus University of Thrace
 * 
 * @brief A dynamic Predictor, containing a gshare predictor for the direction prediction,
 * 		  a branch target buffer for the target prediction, and a return address stack
 *
 * @param PC_BITS : # of PC Bits
 */
module Predictor
	//Parameter List
	#(parameter int PC_BITS          = 32,
	  parameter int RAS_DEPTH        = 8,
	  parameter int GSH_HISTORY_BITS = 2,
	  parameter int GSH_SIZE         = 256,
	  parameter int BTB_SIZE         = 256,
	  parameter int FETCH_WIDTH      = 64)									
	//Input List
	(input logic clk,
	 input logic rst_n,
	 //Control Interface
	 input logic 				  must_flush,
	 input logic 				  is_branch,
	 input logic 				  branch_resolved,
	 //Update Interface
	 input logic                  new_entry,
	 input logic [PC_BITS-1 : 0]  PC_Orig,
	 input logic [PC_BITS-1 : 0]  Target_PC,
	 input logic                  is_Taken,
	 //RAS Interface
	 input logic                  is_return,
	 input logic                  is_jumpl,
	 input logic 			      invalidate,
	 input logic [PC_BITS-1 : 0]  old_PC,
	 //Access Interface
	 input logic [PC_BITS-1 : 0]  PC_in,
	 output logic				  taken_branch_a,
	 output logic [PC_BITS-1 : 0] next_PC_a,
	 output logic				  taken_branch_b,
	 output logic [PC_BITS-1 : 0] next_PC_b);


	// #Internal Signals#
	logic [PC_BITS-1 : 0] PC_in_2, next_PC_btb_a, next_PC_btb_b, PC_out_Ras, new_entry_ras;
	logic Hit_btb_a, Hit_btb_b, Pop, Push, is_empty_ras, is_Taken_out_a, is_Taken_out_b;

	assign PC_in_2        = PC_in + 4;
	assign taken_branch_a = (Hit_btb_a & is_Taken_out_a);
	assign taken_branch_b = (Hit_btb_b & is_Taken_out_b);
	//Initialize the GShare
	GShare #(
		.PC_BITS     (PC_BITS         ),
		.HISTORY_BITS(GSH_HISTORY_BITS),
		.SIZE        (GSH_SIZE        )
	) GShare (
		.clk           (clk           ),
		.rst_n         (rst_n         ),
		.PC_in_a       (PC_in         ),
		.PC_in_b       (PC_in_2       ),
		.is_Taken_out_a(is_Taken_out_a),
		.is_Taken_out_b(is_Taken_out_b),
		
		.Wr_En         (new_entry     ),
		.is_Taken      (is_Taken      ),
		.Orig_PC       (PC_Orig       )
	);
	//Initialize the BTB
	BTB #(
		.PC_BITS(PC_BITS ),
		.SIZE   (BTB_SIZE)
	) BTB (
		.clk       (clk          ),
		.rst_n     (rst_n        ),
		
		.PC_in_a   (PC_in        ),
		.PC_in_b   (PC_in_2      ),
		
		.Wr_En     (new_entry    ),
		.Orig_PC   (PC_Orig      ),
		.Target_PC (Target_PC    ),
		
		.invalidate(invalidate   ),
		.pc_invalid(old_PC       ),
		
		.Hit_a     (Hit_btb_a    ),
		.next_PC_a (next_PC_btb_a),
		.Hit_b     (Hit_btb_b    ),
		.next_PC_b (next_PC_btb_b)
	);
	//Initialize the RAS
	RAS #(
		.PC_BITS(PC_BITS  ),
		.SIZE   (RAS_DEPTH)
	) RAS (
		.clk            (clk                  ),
		.rst_n          (rst_n                ),
		
		.must_flush     (must_flush           ),
		.is_branch      (is_branch & ~is_jumpl),
		.branch_resolved(branch_resolved      ),
		
		.Pop            (Pop                  ),
		.Push           (Push                 ),
		.new_entry      (new_entry_ras        ),
		.PC_out         (PC_out_Ras           ),
		.is_empty       (is_empty_ras         )
	);

	//RAS Drive Signals
	assign Pop  = (is_return & ~is_empty_ras);					
	assign Push = is_jumpl;
	assign new_entry_ras = old_PC +4;

	//Push the Correct PC to the Output
	always_comb begin : PushOutputA
		if(Pop) begin
			next_PC_a = PC_out_Ras;
		end else if(Hit_btb_a && is_Taken_out_a) begin
			next_PC_a = next_PC_btb_a;
		end else begin
			next_PC_a = PC_in+(FETCH_WIDTH/32)*4;
		end
	end
	always_comb begin : PushOutputB
		if(Pop) begin
			next_PC_b = PC_out_Ras;
		end else if(Hit_btb_b && is_Taken_out_b) begin
			next_PC_b = next_PC_btb_b;
		end else begin
			next_PC_b = PC_in_2+(FETCH_WIDTH/32)*4;
		end
	end

endmodule