`ifndef IF_SEQ_LIB_SV
`define IF_SEQ_LIB_SV

class IF_default_seq extends uvm_sequence #(trans);

  `uvm_object_utils(IF_default_seq)

  function new(string name = "");
    super.new(name);
  endfunction : new
  

  task body();
    `uvm_info(get_type_name(), "Sequence starting", UVM_HIGH)

    repeat (TRANS_NUM) begin 
      req = trans::type_id::create("req");
      start_item(req); 
      if ( !req.randomize() )
        `uvm_error(get_type_name(), "Failed to randomize transaction")
      finish_item(req); 
    end

    `uvm_info(get_type_name(), "Sequence completed", UVM_HIGH)
  endtask : body

endclass : IF_default_seq


`endif

