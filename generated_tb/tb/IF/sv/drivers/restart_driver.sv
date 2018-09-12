`ifndef RESTART_DRIVER_SV
`define RESTART_DRIVER_SV

import util_pkg::*;
import drivers_pkg::*;
class restart_driver extends uvm_component;
  `uvm_component_utils(restart_driver)

  virtual IF_if vif;
  bit invalid_Ins, invalid_prediction, function_call, function_return;
  int last_pc;
  int credits = 0;
  int functions_in_flight  = 0; // functions in flight (functions called but not returned yet)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    wait(vif.rst_n);

    forever begin 

      if(vif.valid_o && vif.ready_in) begin
        // credits = Instructions at ID stage
        credits = credits + 2;
        last_pc = vif.current_PC;
      end

      // 
      invalid_Ins         = ($urandom_range(0,99)<INVALID_INS_RATE)        &(credits>0);
      invalid_prediction  = ($urandom_range(0,99)<INVALID_PREDICTION_RATE) &(credits>0);
      function_call       = ($urandom_range(0,99)<FUNCTION_CALL_RATE)      &(credits>0);
      function_return     = ($urandom_range(0,99)<FUNCTION_RETURN_RATE)    &(credits>0) &(functions_in_flight>0);

      if(invalid_Ins) begin
        vif.invalid_instruction <= 1;
        vif.invalid_prediction <= 0;
        vif.is_return_in <= 0;
        vif.is_jumpl <= 0;
        // set as old PC one of the two Instructions fetched at the ID stage
        vif.old_PC <=  last_pc + $urandom_range(0,1)*4;
      end else if(invalid_prediction) begin
        vif.invalid_instruction <= 0;
        vif.invalid_prediction <= 1;
        vif.is_return_in <= 0;
        vif.is_jumpl <= 0;
        // set as old PC one of the two Instructions fetched at the ID stage
        vif.old_PC <= last_pc + $urandom_range(0,1)*4;
      end else if(function_call) begin
        vif.invalid_instruction <= 0;
        vif.invalid_prediction <= 0;
        vif.is_return_in <= 0;
        vif.is_jumpl <= 1;
        // set as old PC one of the two Instructions fetched at the ID stage
        vif.old_PC <= last_pc + $urandom_range(0,1)*4;
        functions_in_flight++;
      end else if(function_return) begin
        vif.invalid_instruction <= 0;
        vif.invalid_prediction <= 0;
        vif.is_return_in <= 1;
        vif.is_jumpl <= 0;
        vif.old_PC <= 0;
        functions_in_flight--;
      end else begin 
        vif.invalid_instruction <= 0;
        vif.invalid_prediction <= 0;
        vif.is_return_in <= 0;
        vif.is_jumpl <= 0;
        vif.old_PC <= 0;
      end

      if(credits>0) credits = 0;
      @(posedge vif.clk);
    end
    
  endtask

endclass 



`endif 

