`ifndef IF_SEQ_ITEM_SV
`define IF_SEQ_ITEM_SV

import util_pkg::*;
class trans extends uvm_sequence_item; 
  `uvm_object_utils(trans)

  rand bit[INSTR_COUNT-1:0][INSTR_BITS-1:0] Ins_data;
  // Just for debug, remove this later
  static int trans_counter_dbg;
  int trans_id_dbg;

  function new(string name = "");
    super.new(name);
    trans_counter_dbg++;
    trans_id_dbg = trans_counter_dbg-1;
  endfunction : new


endclass : trans 

`endif