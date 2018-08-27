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
    vif.ready_in   <= 0;
    vif.must_flush <= 0;
    vif.Hit_cache  <= 0;
    vif.Miss       <= 0;
  endfunction

  task icache_driver();
    forever begin 
      seq_item_port.get_next_item(req);
      vif.trans_id_dbg <= req.trans_id_dbg;
      
      while($urandom_range(0,99)<ICACHE_MISS_RATE) begin
        // Miss
        vif.Hit_cache <= 0;
        vif.Miss <= 1;
        vif.partial_access <= 0;
        vif.partial_type <= 0;
        // vif.fetched_data <= $random;
        @(posedge vif.clk);
      end
      icache_port.write(req);

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
      trans_pointer_synced++;
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
    int pc_pointers[$];
    int credits = 0;
    int pc_pointer = 0;
    int pc_1, pc_2;
    forever begin 
      // credits counter = Ins passed through IF stage to ID stage
      if(vif.valid_o && vif.ready_in) begin
        credits = credits + INSTR_COUNT;
        pc_1 = vif.current_PC;
        pc_2 = vif.current_PC + 4;
        pc_pointers.push_back(pc_1);
        pc_pointers.push_back(pc_2);
      end

      if (credits>0) begin  // while dn tha eprepe? kai na mporw na stelnw 2 pr_update per cycle? #ask
        assert(pc_pointers.size()>0) else $fatal("Popping on empty queue: pc_pointers");
        pc_pointer = (pc_pointers.pop_front()/4);
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
    int pc_pointers[$];
    int credits = 0;
    int pc_pointer = 0;
    int pc_1, pc_2;

    forever begin 
      if(vif.valid_o && vif.ready_in) begin
        pc_1 = vif.current_PC/4;
        pc_2 = (vif.current_PC+4)/4;
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

  task restart_driver();
    int last_pc;
    int credits = 0;
    int fnc_if  = 0; // functions in flight (functions called but not returned yet)
    bit invalid_Ins, invalid_prediction, function_call, function_return;
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
      function_return     = ($urandom_range(0,99)<FUNCTION_RETURN_RATE)    &(credits>0) &(fnc_if>0);

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
        fnc_if ++;
      end else if(function_return) begin
        vif.invalid_instruction <= 0;
        vif.invalid_prediction <= 0;
        vif.is_return_in <= 1;
        vif.is_jumpl <= 0;
        vif.old_PC <= 0;
        fnc_if --;
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

