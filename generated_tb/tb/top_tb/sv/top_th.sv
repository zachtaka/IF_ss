// You can insert code here by setting file_header_inc in file common.tpl

//=============================================================================
// Project  : generated_tb
//
// File Name: top_th.sv
//
//
// Version:   1.0
//
// Code created by Easier UVM Code Generator version 2016-08-11 on Wed Aug  8 13:55:33 2018
//=============================================================================
// Description: Test Harness
//=============================================================================
import util_pkg::*;
module top_th;

  timeunit      1ns;
  timeprecision 1ps;


  // You can remove clock and reset below by setting th_generate_clock_and_reset = no in file common.tpl

  // Example clock and reset declarations
  logic clock = 0;
  logic reset;

  // Example clock generator process
  always #10 clock = ~clock;

  // Example reset generator process
  initial
  begin
    reset = 0;         // Active low reset in this example
    #75 reset = 1;
  end

  IF_if  IF_if_0 ();
  assign IF_if_0.clk = clock;
  assign IF_if_0.rst_n = reset;
  // You can insert code here by setting th_inc_inside_module in file common.tpl

  // Pin-level interfaces connected to DUT
  // You can remove interface instances by setting generate_interface_instance = no in the interface template file


  IF #( 
      .PC_BITS         (PC_BITS),
      .INSTR_BITS      (INSTR_BITS),
      .FETCH_WIDTH     (FETCH_WIDTH),
      .PACKET_SIZE     (PACKET_SIZE),
      .RAS_DEPTH       (RAS_DEPTH),
      .GSH_HISTORY_BITS(GSH_HISTORY_BITS),
      .GSH_SIZE        (GSH_SIZE),
      .BTB_SIZE        (BTB_SIZE)
    ) uut (
    .clk                (IF_if_0.clk),
    .rst_n              (IF_if_0.rst_n),
    .data_out           (IF_if_0.data_out),
    .valid_o            (IF_if_0.valid_o),
    .ready_in           (IF_if_0.ready_in),
    .is_branch          (IF_if_0.is_branch),
    .pr_update          (IF_if_0.pr_update),
    .invalid_instruction(IF_if_0.invalid_instruction),
    .invalid_prediction (IF_if_0.invalid_prediction),
    .is_return_in       (IF_if_0.is_return_in),
    .is_jumpl           (IF_if_0.is_jumpl),
    .old_PC             (IF_if_0.old_PC),
    .must_flush         (IF_if_0.must_flush),
    .correct_address    (IF_if_0.correct_address),
    .current_PC         (IF_if_0.current_PC),
    .Hit_cache          (IF_if_0.Hit_cache),
    .Miss               (IF_if_0.Miss),
    .partial_access     (IF_if_0.partial_access),
    .partial_type       (IF_if_0.partial_type),
    .fetched_data       (IF_if_0.fetched_data)
  );


endmodule

