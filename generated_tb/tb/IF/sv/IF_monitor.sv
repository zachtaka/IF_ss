// You can insert code here by setting file_header_inc in file common.tpl

//=============================================================================
// Project  : generated_tb
//
// File Name: IF_monitor.sv
//
//
// Version:   1.0
//
// Code created by Easier UVM Code Generator version 2016-08-11 on Wed Aug  8 13:55:33 2018
//=============================================================================
// Description: Monitor for IF
//=============================================================================

`ifndef IF_MONITOR_SV
`define IF_MONITOR_SV

// You can insert code here by setting monitor_inc_before_class in file IF.tpl

class IF_monitor extends uvm_monitor;

  `uvm_component_utils(IF_monitor)

  virtual IF_if vif;

  uvm_analysis_port #(trans) analysis_port;

  extern function new(string name, uvm_component parent);

  // You can insert code here by setting monitor_inc_inside_class in file IF.tpl

endclass : IF_monitor 


function IF_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
  analysis_port = new("analysis_port", this);
endfunction : new


// You can insert code here by setting monitor_inc_after_class in file IF.tpl

`endif // IF_MONITOR_SV

