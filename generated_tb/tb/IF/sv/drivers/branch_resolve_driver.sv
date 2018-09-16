`ifndef BRANCH_RESOLVE_DRIVER_SV
`define BRANCH_RESOLVE_DRIVER_SV

import util_pkg::*;
import drivers_pkg::*;
class branch_resolve_driver extends uvm_component;
  `uvm_component_utils(branch_resolve_driver)

  uvm_analysis_port #(predictor_update) pr_update_port;
  predictor_update pr_item;

  virtual IF_if vif;
  int pc_pointers[$];
  int credits = 0;
  int pc_pointer = 0;
  int pc_1, pc_2;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    pr_update_port = new("pr_update_port",this);
  endfunction

  task run_phase(uvm_phase phase);
    fork 
      monitor_pr();
      pr_driver();
    join_none
  endtask

  fetched_packet packet_a, packet_b;
  task pr_driver();
    wait(vif.rst_n);
    forever begin 
      // credits counter = Ins passed through IF stage to ID stage
      if(vif.valid_o && vif.ready_in) begin
        {packet_b,packet_a} = vif.data_out;
        credits = credits + INSTR_COUNT;
        pc_1 = packet_a.pc;
        pc_2 = packet_b.pc;
        pc_pointers.push_back(pc_1);
        pc_pointers.push_back(pc_2);
      end

      if (credits>0) begin  // while dn tha eprepe? kai na mporw na stelnw 2 pr_update per cycle? #ask
        assert(pc_pointers.size()>0) else $fatal("Popping on empty queue: pc_pointers");
        pc_pointer = (pc_pointers.pop_front()/4);
        if(PC_Ins_mapping_array[pc_pointer].is_branch) begin
          vif.is_branch <= 1;
          vif.pr_update.valid_jump <= 1;
          vif.pr_update.orig_pc <= PC_Ins_mapping_array[pc_pointer].orig_pc;
          vif.pr_update.jump_address <= PC_Ins_mapping_array[pc_pointer].target_pc;
          if(PC_Ins_mapping_array[pc_pointer].backward_jump) begin
            vif.pr_update.jump_taken <= ($urandom_range(0,99)<BACK_BRANCH_IS_TAKEN_RATE);
          end else begin 
            vif.pr_update.jump_taken <= ($urandom_range(0,99)<FORW_BRANCH_IS_TAKEN_RATE);
          end
        end else begin 
          vif.is_branch <= 0;
          vif.pr_update.valid_jump <= 0;
          vif.pr_update.orig_pc <= 0;
          vif.pr_update.jump_address <= 0;
          vif.pr_update.jump_taken <= 0;
        end
        credits--;
      end else begin 
        vif.is_branch <= 0;
        vif.pr_update.valid_jump <= 0;
        vif.pr_update.orig_pc <= 0;
        vif.pr_update.jump_address <= 0;
        vif.pr_update.jump_taken <= 0;
      end
      @(posedge vif.clk);
    end
  endtask

  task monitor_pr();
    forever begin 
      // If valid jump broadcast to checker
      if(vif.pr_update.valid_jump) begin
        pr_item = vif.pr_update;
        // if(pr_item.orig_pc==628) $display("[PR DRIVER] @ %0t ps sent pr_update=%p",$time(),pr_item);
        pr_update_port.write(pr_item);
      end
      @(negedge vif.clk);
    end
  endtask

endclass 



`endif 

