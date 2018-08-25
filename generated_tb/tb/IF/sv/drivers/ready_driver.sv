`ifndef READY_DRIVER_SV
`define READY_DRIVER_SV

import util_pkg::*;
import drivers_pkg::*;
class ready_driver extends uvm_component;
  `uvm_component_utils(ready_driver)

  virtual IF_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void reset();
    vif.ready_in   <= 0;
  endfunction

  task run_phase(uvm_phase phase);
    reset();
    wait(vif.rst_n);

    forever begin 
      if($urandom_range(0,99)<ID_NOT_READY_RATE) begin
        vif.ready_in <= 0;
      end else begin 
        vif.ready_in <= 1;
      end
      @(posedge vif.clk);
    end

  endtask

endclass 



`endif 

