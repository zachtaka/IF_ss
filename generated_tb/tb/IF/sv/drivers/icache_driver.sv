`ifndef ICACHE_DRIVER_SV
`define ICACHE_DRIVER_SV

import util_pkg::*;
import drivers_pkg::*;
class icache_driver extends uvm_driver #(trans);
  `uvm_component_utils(icache_driver)

  uvm_analysis_port #(trans) icache_port;
  virtual IF_if vif;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    icache_port = new("icache_port",this);
    initialize_Instructions();
  endfunction

  function void reset();
    vif.Hit_cache  <= 0;
    vif.Miss       <= 0;
  endfunction


  task run_phase(uvm_phase phase);
    bit partial_access_second_part;

    reset();
    wait(vif.rst_n);

    forever begin 
      seq_item_port.get_next_item(req);
      vif.trans_id_dbg <= req.trans_id_dbg;
      $display("@ %0t ps trans_pointer_synced=%0d",$time(),trans_pointer_synced);
      // Miss
      while($urandom_range(0,99)<ICACHE_MISS_RATE) begin
        vif.Hit_cache <= 0;
        vif.Miss <= 1;
        vif.partial_access <= 0;
        vif.partial_type <= 0;
        @(posedge vif.clk);
      end
      icache_port.write(req);

      // Hit
      if(($urandom_range(0,99)<ICACHE_PARTIAL_ACCESS_RATE)&&(!partial_access_second_part)) begin
        // New partial access issue
        vif.Hit_cache <= 1;
        vif.Miss <= 0;
        vif.partial_access <= 1;
        vif.partial_type <= 2; // #Todo change it again to 1-3 when bug 8 is fixed
        // vif.partial_type <= $urandom_range(1,3);
        vif.fetched_data <= req.data;
        partial_access_second_part = 1;
      end else begin 
        // Normal operation
        vif.Hit_cache <= 1;
        vif.Miss <= 0;
        vif.partial_access <= 0;
        vif.partial_type <= 0;
        vif.fetched_data <= req.data;
        partial_access_second_part = 0;
      end


      @(posedge vif.clk);

      while (!vif.ready_in && vif.valid_o) begin 
        @(posedge vif.clk);
      end

      trans_properties[trans_pointer_synced].valid = 1;
      $display("[DEBUG2]@ %0t ps trans_properties[%0d].valid=%b",$time(),trans_pointer_synced,trans_properties[trans_pointer_synced].valid);
      trans_pointer_synced++;
      seq_item_port.item_done();
    end

  endtask : run_phase

endclass : icache_driver 



`endif 

