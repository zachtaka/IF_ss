package drivers_pkg;
  import util_pkg::*;

  typedef struct packed{
    bit is_branch;
    bit backward_jump;
    bit function_call;
    bit [PC_BITS-1:0] orig_pc;
    bit [PC_BITS-1:0] target_pc;
	}	PC_Ins_mapping_entry;

	PC_Ins_mapping_entry [TRANS_NUM*INSTR_COUNT*2-1:0] PC_Ins_mapping_array;


	function void initialize_Instructions();
		// Instruction mapping
    $display("--------------------\nPC_Ins_mapping_array: \n");
    for (int i = 0; i < TRANS_NUM*INSTR_COUNT*2; i++) begin
      PC_Ins_mapping_array[i].is_branch = ($urandom_range(0,99)<INS_BRANCH_RATE);
      PC_Ins_mapping_array[i].function_call = ($urandom_range(0,99)<FUNCTION_CALL_RATE)&(~PC_Ins_mapping_array[i].is_branch);
      PC_Ins_mapping_array[i].orig_pc = i*(PC_BITS/8);
      if(PC_Ins_mapping_array[i].is_branch) begin
        PC_Ins_mapping_array[i].backward_jump = ($urandom_range(0,99)<BACK_BRANCH_RATE)&(i>8);
        if(PC_Ins_mapping_array[i].backward_jump) begin
          PC_Ins_mapping_array[i].target_pc = PC_Ins_mapping_array[i].orig_pc - $urandom_range(4,8)*4;
        end else begin 
          PC_Ins_mapping_array[i].target_pc = PC_Ins_mapping_array[i].orig_pc + $urandom_range(4,8)*4;
        end
      end
      $display("PC_Ins_mapping_array[%2d]: br=%0b fnc=%0b b_jump=%0b or_pc=%0d tr_pc=%0d",i,PC_Ins_mapping_array[i].is_branch,PC_Ins_mapping_array[i].function_call,PC_Ins_mapping_array[i].backward_jump,PC_Ins_mapping_array[i].orig_pc,PC_Ins_mapping_array[i].target_pc);
    end
    $display("--------------------\n");
	endfunction 



endpackage