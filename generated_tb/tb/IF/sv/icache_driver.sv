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

    // Instruction mapping
    $display("--------------------\nPC_Ins_mapping_array: \n");
    for (int i = 0; i < TRANS_NUM*INSTR_COUNT*2; i++) begin
      PC_Ins_mapping_array[i].is_branch = ($urandom_range(0,99)<INS_BRANCH_RATE);
      PC_Ins_mapping_array[i].orig_pc = i*(PC_BITS/8);
      if(PC_Ins_mapping_array[i].is_branch) begin
        PC_Ins_mapping_array[i].backward_jump = ($urandom_range(0,99)<BACK_BRANCH_RATE)&(i>8);
        if(PC_Ins_mapping_array[i].backward_jump) begin
          PC_Ins_mapping_array[i].target_pc = PC_Ins_mapping_array[i].orig_pc - $urandom_range(4,8)*4;
        end else begin 
          PC_Ins_mapping_array[i].target_pc = PC_Ins_mapping_array[i].orig_pc + $urandom_range(4,8)*4;
        end
      end
      $display("PC_Ins_mapping_array[%2d]: is_branch=%0b backward_jump=%0b orig_pc=%0d target_pc=%0d",i,PC_Ins_mapping_array[i].is_branch,PC_Ins_mapping_array[i].backward_jump,PC_Ins_mapping_array[i].orig_pc,PC_Ins_mapping_array[i].target_pc);
    end
    $display("--------------------\n");
  endfunction

  function void reset();
    vif.ready_in   <= 0;
    vif.must_flush <= 0;
    vif.Hit_cache  <= 0;
    vif.Miss       <= 0;
  endfunction

  task icache_driver();
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
    int credits = 0;
    int pc_pointer = 0;

    forever begin 
      // credits counter = Ins passed through IF stage 
      if(vif.valid_o && vif.ready_in) begin
        credits = credits + INSTR_COUNT;
      end

      if (credits>0) begin  // while dn tha eprepe? kai na mporw na stelnw 2 pr_update per cycle? #ask
        if(PC_Ins_mapping_array[pc_pointer].is_branch) begin
          vif.is_branch = 1;
          vif.pr_update.valid_jump = 1;
          vif.pr_update.orig_pc = PC_Ins_mapping_array[pc_pointer].orig_pc;
          vif.pr_update.jump_address = PC_Ins_mapping_array[pc_pointer].target_pc;
          if(PC_Ins_mapping_array[pc_pointer].backward_jump) begin
            vif.pr_update.jump_taken = ($urandom_range(0,99)<BACK_BRANCH_IS_TAKEN_RATE);
          end else begin 
            vif.pr_update.jump_taken = ($urandom_range(0,99)<FORW_BRANCH_IS_TAKEN_RATE);
          end
        end else begin 
          vif.is_branch = 0;
          vif.pr_update.valid_jump = 0;
          vif.pr_update.orig_pc = 0;
          vif.pr_update.jump_address = 0;
          vif.pr_update.jump_taken = 0;
        end

        pc_pointer++;
        credits--;
      end else begin 
        vif.is_branch = 0;
        vif.pr_update.valid_jump = 0;
        vif.pr_update.orig_pc = 0;
        vif.pr_update.jump_address = 0;
        vif.pr_update.jump_taken = 0;
      end
      
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
      icache_driver();
      predictor_update_driver();
    join

  endtask : run_phase

endclass : icache_driver 



`endif 

