// You can insert code here by setting file_header_inc in file common.tpl

//=============================================================================
// Project  : generated_tb
//
// File Name: IF_if.sv
//
//
// Version:   1.0
//
// Code created by Easier UVM Code Generator version 2016-08-11 on Wed Aug  8 13:55:33 2018
//=============================================================================
// Description: Signal interface for agent IF
//=============================================================================

`ifndef IF_IF_SV
`define IF_IF_SV
import util_pkg::*;
interface IF_if(); 

  timeunit      1ns;
  timeprecision 1ps;

  import IF_pkg::*;

  logic clk;
  logic rst_n;
  logic [2*PACKET_SIZE-1:0] data_out;
  logic                     valid_o;
  logic                     ready_in;
  logic                     is_branch;
  predictor_update          pr_update;
  logic                     invalid_instruction;
  logic                     invalid_prediction;
  logic                     is_return_in;
  logic                     is_jumpl;
  logic [PC_BITS-1:0]       old_PC;
  logic                     must_flush;
  logic [PC_BITS-1:0]       correct_address;
  logic [PC_BITS-1:0]       current_PC;
  logic                     Hit_cache;
  logic                     Miss;
  logic                     partial_access;
  logic [1:0]               partial_type;
  logic [FETCH_WIDTH-1:0]   fetched_data;

  // You can insert properties and assertions here

  // You can insert code here by setting if_inc_inside_interface in file IF.tpl

endinterface : IF_if

`endif // IF_IF_SV

