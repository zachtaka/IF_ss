`ifndef IF_SEQ_ITEM_SV
`define IF_SEQ_ITEM_SV

import util_pkg::*;
class trans extends uvm_sequence_item; 
  `uvm_object_utils(trans)

  rand bit[INSTR_COUNT-1:0][INSTR_BITS-1:0] Ins_data;

  function new(string name = "");
    super.new(name);
  endfunction : new


endclass : trans 

`endif