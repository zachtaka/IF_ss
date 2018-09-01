`ifndef FLUSH_DRIVER_SV
`define FLUSH_DRIVER_SV

import util_pkg::*;
import drivers_pkg::*;
class flush_driver extends uvm_component;
  `uvm_component_utils(flush_driver)

  virtual IF_if vif;
  int pc_pointers[$];
  int credits = 0;
  int pc_pointer = 0;
  int pc_1, pc_2;
  fetched_packet packet_a, packet_b;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void reset();
    vif.must_flush <= 0;
  endfunction

  task run_phase(uvm_phase phase);
    reset();
    wait(vif.rst_n);

    forever begin 
      if(vif.valid_o && vif.ready_in) begin
        {packet_b,packet_a} = vif.data_out;
        pc_1 = packet_a.pc/4;
        pc_2 = packet_b.pc/4;
        if(PC_Ins_mapping_array[pc_1].is_branch) begin
          credits++;
        end
        if(PC_Ins_mapping_array[pc_2].is_branch) begin
          credits++;
        end
      end

      if(($urandom_range(0,99)<FLUSH_RATE)&&(credits>0)) begin
        vif.must_flush <= 1;
        vif.correct_address <= $urandom_range(0,vif.current_PC/4)*4;
        credits=0;
      end else if(credits>0) begin
        vif.must_flush <= 0;
        vif.correct_address <= 0;
        credits--;
      end else begin 
        vif.must_flush <= 0;
        vif.correct_address <= 0;
      end
        
      @(posedge vif.clk);
    end

  endtask

endclass 



`endif 

