`ifndef ICACHE_DRIVER_SV
`define ICACHE_DRIVER_SV

import util_pkg::*;
class icache_driver extends uvm_driver #(trans);
  `uvm_component_utils(icache_driver)

  uvm_analysis_port #(trans) icache_port;
  virtual IF_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    icache_port = new("icache_port",this);
  endfunction : new

  function void reset();
    vif.ready_in   <= 0;
    vif.must_flush <= 0;
    vif.Hit_cache  <= 0;
    vif.Miss       <= 0;
  endfunction : reset

  task cache_driver();
    forever begin 
      seq_item_port.get_next_item(req);
      icache_port.write(req);
      
      while($urandom_range(0,99)<ICACHE_MISS_RATE) begin
        // Miss
        vif.Hit_cache <= 0;
        vif.Miss <= 1;
        vif.partial_access <= 0;
        vif.partial_type <= 0;
        // vif.fetched_data <= $random;
        @(posedge vif.clk);
      end

      // Hit
      vif.Hit_cache <= 1;
      vif.Miss <= 0;
      vif.partial_access <= 0;
      vif.partial_type <= 0;
      vif.fetched_data <= req.Ins_data;
      @(posedge vif.clk);

      while (!vif.ready_in && vif.valid_o) begin 
        @(posedge vif.clk);
      end

      seq_item_port.item_done();
    end
  endtask

  task ready_driver();
    forever begin 
      //Output Interface
      if($urandom_range(0,99)<ID_NOT_READY_RATE) begin
        vif.ready_in <= 0;
      end else begin 
        vif.ready_in <= 1;
      end
      @(posedge vif.clk);
    end
  endtask

  task predictor_update_driver();
    forever begin 
      //Predictor Update Interface
      vif.is_branch <= 0;
      // vif.pr_update. <= 
      @(posedge vif.clk);
    end
  endtask

  task flush_driver();
    forever begin 
      //Flush Interface
      vif.must_flush <= 0;
      vif.correct_address <= 0;
      @(posedge vif.clk);
    end
  endtask

  task restart_driver();
    forever begin 
      //Restart Interface
      vif.invalid_instruction <= 0;
      vif.invalid_prediction <= 0;
      vif.is_return_in <= 0;
      vif.is_jumpl <= 0;
      vif.old_PC <= 0;
      @(posedge vif.clk);
    end
  endtask


  task run_phase(uvm_phase phase);

    reset();
    wait(vif.rst_n);

    // tb will never end, change to icache driver with transaction
    fork
      restart_driver();
      flush_driver();
      ready_driver();
      cache_driver();
      predictor_update_driver();
    join

  endtask : run_phase

endclass : icache_driver 



`endif 

