package drivers_pkg;
  import util_pkg::*;

  typedef struct packed{
    bit is_branch;
    bit backward_jump;
    bit [PC_BITS-1:0] orig_pc;
    bit [PC_BITS-1:0] target_pc;
	}	PC_Ins_mapping_entry;

	PC_Ins_mapping_entry [TRANS_NUM*INSTR_COUNT*2-1:0] PC_Ins_mapping_array;



endpackage