`ifndef Checker_sv
`define Checker_sv
`uvm_analysis_imp_decl(_pr) 

import util_pkg::*;
class Checker extends uvm_subscriber #(trans);
  `uvm_component_utils(Checker)

  virtual IF_if vif;
  uvm_analysis_imp_pr #(predictor_update, Checker) pr; 
  Checker_utils utils;

  int current_pc_gr, next_pc;
  fetched_packet[INSTR_COUNT-1:0] gr_packet_, dut_packet_;
  bit [INSTR_COUNT*(PC_BITS+INSTR_BITS+1)-1:0] data_out_gr;
  output_array_s [TRANS_NUM-1:0] gr_array, dut_array;
  int trans_pointer=0;
  int trans_pointer_synced = -1; // transaction pointer synced with driver
  predictor_update pr_queue[$];
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name,parent);
    pr = new("pr",this);
    utils = new();
    current_pc_gr = 0;
    next_pc = 0;
  endfunction

  function void write_pr(input predictor_update t);
    // if(t.orig_pc==628)$display("[CHECKER] @ %0t ps predictor update=%p",$time(),t);
    pr_queue.push_back(t);
  endfunction

  trans trans_q[$];
  function void write(trans t);
    trans_q.push_back(t);
    // $display("@ %0t ps trans_pointer_synced=%0d",$time(),trans_pointer_synced);
    trans_pointer_synced++;
  endfunction


  monitor_DUT_s [TRANS_NUM-1:0] trans_properties;
  int restart_PC, flush_PC;
  bit valid_o_gr;
  bit[1:0] is_taken;
  bit btb_hit;
  btb_read_s btb_read, btb;
  task GR_model();
    trans trans;
    predictor_update pr_trans;
    int orig_1 = 0;
    int orig_2 = 0;
    bit is_taken_a, is_taken_b;
    forever begin 
      if(trans_q.size()>0) begin
        trans = trans_q.pop_front();
        wait(trans_properties[trans_pointer].valid);
        // Calculate current pc and data_out
        current_pc_gr = next_pc;
        $display("[GR] @ %0t ps current_pc_gr[%0d]=%0d orig_1=%0d orig_2=%0d",$time(),trans_pointer,current_pc_gr,orig_1,orig_2);
        for (int i = 0; i < INSTR_COUNT; i++) begin
          gr_packet_[i].pc = current_pc_gr + i*(PC_BITS/8);
          gr_packet_[i].data = trans.Ins_data[i];
          btb = utils.btb_read(gr_packet_[i].pc);
          is_taken[i] = (utils.gsh_read(gr_packet_[i].pc)&btb.hit);
          gr_packet_[i].taken_branch = is_taken[i];
          $display("[GR] @ %0t ps gr_packet_[%0d]=%p ",$time(),i,gr_packet_[i]);
        end
        valid_o_gr = ~trans_properties[trans_pointer].invalid_instruction;
        $display("trans_properties[%0d]=%p",trans_pointer,trans_properties[trans_pointer]);
        // Save results for report_phase
        gr_array[trans_pointer].current_pc_gr = current_pc_gr;
        for (int i = 0; i < INSTR_COUNT; i++) begin
          gr_array[trans_pointer].packet_[i].pc = gr_packet_[i].pc;
          gr_array[trans_pointer].packet_[i].data = gr_packet_[i].data;
          gr_array[trans_pointer].packet_[i].taken_branch = gr_packet_[i].taken_branch;
        end

        if(trans_properties[trans_pointer].invalid_instruction) begin
          next_pc = trans_properties[trans_pointer].restart_PC;
          orig_1 = 0;
        end else if(trans_properties[trans_pointer].invalid_prediction) begin
          next_pc = trans_properties[trans_pointer].restart_PC;
          orig_1 = 1;
        end else if((trans_properties[trans_pointer].function_return)&&(utils.ras_queue.size()>0)) begin
          next_pc = utils.ras_pop() + 4;
          orig_1 = 2;
        end else begin 
          // Normal operation
          // 1) check if the PC address corresponds to a taken branch (from Gshare)
          // 2) If it is taken, we search for the target address from BTB
          // 3) If BTB hits we grab it else just increment the current pc
          is_taken_a = gr_array[trans_pointer].packet_[0].taken_branch;
          is_taken_b = gr_array[trans_pointer].packet_[1].taken_branch;
          if(is_taken_a) begin
            btb_read = utils.btb_read(gr_array[trans_pointer].packet_[0].pc);
            if(btb_read.hit) begin
              next_pc = btb_read.target_pc;
              orig_2 = 0;
            end else begin 
              next_pc = current_pc_gr + INSTR_COUNT*(PC_BITS/8);
              orig_2 = 1;
            end
          end else if(is_taken_b) begin
            btb_read = utils.btb_read(gr_array[trans_pointer].packet_[1].pc);
            if(btb_read.hit) begin
              next_pc = btb_read.target_pc;
              orig_2 = 2;
            end else begin 
              next_pc = current_pc_gr + INSTR_COUNT*(PC_BITS/8);
              orig_2 = 3;
            end
          end else begin 
            next_pc = current_pc_gr + INSTR_COUNT*(PC_BITS/8);
            orig_2 = 4;
          end
          orig_1 = 3;
        end

        // Update checker components: Gshare, BTB, RAS
        while (pr_queue.size()>0) begin 
          pr_trans = pr_queue.pop_front();
          if(pr_trans.valid_jump) begin
            utils.gsh_update(pr_trans.orig_pc, pr_trans.jump_taken);
            utils.btb_update(pr_trans.orig_pc, pr_trans.jump_address);
          end
        end
        if(trans_properties[trans_pointer].function_call) begin
          utils.ras_push(trans_properties[trans_pointer].function_call_PC);
        end

        trans_pointer++;
      end
      @(posedge vif.clk);
    end

  endtask


  task monitor_DUT_output();
    int trans_pointer = 0;

    forever begin 
      if(vif.Hit_cache)begin
        dut_array[trans_pointer_synced].current_pc_gr = vif.current_PC;
        {dut_array[trans_pointer_synced].packet_[1],dut_array[trans_pointer_synced].packet_[0]} = vif.data_out;
        dut_array[trans_pointer_synced].valid_o_gr = vif.valid_o;
        dut_array[trans_pointer_synced].sim_time = $time();
        $display("[DUT] @ %0t ps current_pc[%0d]=%0d ",$time(),trans_pointer_synced,dut_array[trans_pointer_synced].current_pc_gr);
        $display("[DUT] @ %0t ps packet_[0]=%p ",$time(),dut_array[trans_pointer_synced].packet_[0]);
        $display("[DUT] @ %0t ps packet_[1]=%p ",$time(),dut_array[trans_pointer_synced].packet_[1]);
        // $display("@ %0t ps trans_pointer_synced=%0d",$time(),trans_pointer_synced);
        // trans_pointer++;
      end
      @(negedge vif.clk);
    end
  
  endtask

  task monitor_trans_properties();
    // int trans_pointer = 0;
    bit restart;
    forever begin 
      restart = 0;
      // Restart properties
      // Invalid instruction
      if(vif.invalid_instruction) begin 
         trans_properties[trans_pointer_synced].invalid_instruction = 1;
         trans_properties[trans_pointer_synced].restart_PC = vif.old_PC;
         restart = 1;
      end
      // Invalid prediction
      if(vif.invalid_prediction) begin 
        trans_properties[trans_pointer_synced].invalid_prediction = 1;
        trans_properties[trans_pointer_synced].restart_PC = vif.old_PC;
        restart = 1;
      end
      // Function return
      if(vif.is_return_in) begin 
        trans_properties[trans_pointer_synced].function_return = 1;
        restart = 1;
      end
      // Function call
      if(vif.is_jumpl) begin 
        trans_properties[trans_pointer_synced].function_call = 1;
        trans_properties[trans_pointer_synced].function_call_PC = vif.old_PC;
        restart = 1;
      end
      // Pipeline flush
      if(vif.must_flush) begin 
        trans_properties[trans_pointer_synced].flushed = 1;
        trans_properties[trans_pointer_synced].flush_PC = vif.correct_address;
        restart = 1;
      end

      trans_properties[trans_pointer_synced].valid = 1;

      @(negedge vif.clk);
    end
  endtask


  

  task run_phase(uvm_phase phase);
    fork 
      monitor_DUT_output();
      monitor_trans_properties();
      GR_model();
    join_none
  endtask

  function void report_phase(uvm_phase phase);
    int correct_pc = 0;
    int wrong_pc = 0;
    int correct_pc2 = 0;
    int wrong_pc2 = 0;
    int correct_data = 0;
    int wrong_data = 0;
    int correct_branch_taken = 0;
    int wrong_branch_taken = 0;

    for (int i = 0; i < TRANS_NUM; i++) begin
      if(gr_array[i].current_pc_gr != dut_array[i].current_pc_gr) begin  
        `uvm_error(get_type_name(),$sformatf("[CHECKER] @ %0t ps Expected: current_pc_gr[%0d]=%0d Recieved:%0d", dut_array[i].sim_time,i,gr_array[i].current_pc_gr,dut_array[i].current_pc_gr))
        wrong_pc++;
      end else begin
        correct_pc++;
      end 

      for (int ins_i = 0; ins_i < INSTR_COUNT; ins_i++) begin
        if(gr_array[i].packet_[ins_i].pc != dut_array[i].packet_[ins_i].pc) begin  
          `uvm_error(get_type_name(),$sformatf("[CHECKER] @ %0t ps Expected: gr_array[%0d].packet[%0d].pc=%0d Recieved:%0d", dut_array[i].sim_time,i,ins_i,gr_array[i].packet_[ins_i].pc,dut_array[i].packet_[ins_i].pc))
          wrong_pc2++;
        end else begin
          correct_pc2++;
        end 

        if(gr_array[i].packet_[ins_i].data != dut_array[i].packet_[ins_i].data) begin  
          `uvm_error(get_type_name(),$sformatf("[CHECKER] @ %0t ps Expected: gr_array[%0d].packet[%0d].data=%0d Recieved:%0d", dut_array[i].sim_time,i,ins_i,gr_array[i].packet_[ins_i].data,dut_array[i].packet_[ins_i].data))
          wrong_data++;
        end else begin
          correct_data++;
        end 

        if(gr_array[i].packet_[ins_i].taken_branch != dut_array[i].packet_[ins_i].taken_branch) begin  
          `uvm_error(get_type_name(),$sformatf("[CHECKER] @ %0t ps Expected: gr_array[%0d].packet[%0d].taken_branch=%0d Recieved:%0d", dut_array[i].sim_time,i,ins_i,gr_array[i].packet_[ins_i].taken_branch,dut_array[i].packet_[ins_i].taken_branch))
          wrong_branch_taken++;
        end else begin
          correct_branch_taken++;
        end 
        
      end

    end

    $display("correct_pc   =%0d",correct_pc);
    $display("correct_pc2  =%0d",correct_pc2);
    $display("correct_data =%0d",correct_data);
    $display("correct_branch_taken =%0d",correct_branch_taken);
    $display("wrong_pc     =%0d",wrong_pc);
    $display("wrong_pc2    =%0d",wrong_pc2);
    $display("wrong_data   =%0d",wrong_data);
    $display("wrong_branch_taken   =%0d",wrong_branch_taken);
  endfunction

  function void start_of_simulation_phase( uvm_phase phase );
    // UVM_FILE IF_checker_file;
    // IF_checker_file = $fopen("IF_checker.txt","w");
    // set_report_severity_action(UVM_INFO,UVM_LOG);
    // set_report_severity_action(UVM_ERROR,UVM_LOG);
    // set_report_default_file( IF_checker_file );
  endfunction

  



endclass

`endif