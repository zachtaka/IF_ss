`ifndef Checker_sv
`define Checker_sv
`uvm_analysis_imp_decl(_pr) 

import util_pkg::*;
import drivers_pkg::*;
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
  // int trans_pointer_synced = -1; // transaction pointer synced with driver
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
    // if(t.orig_pc==672)$display("[CHECKER] @ %0t ps predictor update=%p",$time(),t);
    // pr_queue.push_back(t);
    // while ((pr_queue.size()>0)) begin 
        // pr_trans = pr_queue.pop_front();
        if(t.valid_jump) begin
            utils.gsh_update(t.orig_pc, t.jump_taken);
            utils.btb_update(t.orig_pc, t.jump_address);
        end
    // end
  endfunction

  trans trans_q[$];
  function void write(trans t);
    trans_q.push_back(t);
    // $display("@ %0t ps trans_pointer_synced=%0d",$time(),trans_pointer_synced);
    // trans_pointer_synced++;
  endfunction


  monitor_DUT_s [TRANS_NUM-1:0] trans_properties;
  int restart_PC, flush_PC;
  int pc_a, pc_b;
  
  bit valid_o_gr;
  bit[1:0] is_taken;
  bit btb_hit;
  btb_read_s btb_read, btb;
  bit fetch_second_ins;
  task GR_model();
    trans trans;
    predictor_update pr_trans;
    int orig_1 = 0;
    int orig_2 = 0;
    bit is_taken_a, is_taken_b;
    int next_pc_1=0; 
    int next_pc_2=4;
    forever begin 
        if(trans_q.size()>0) begin
            trans = trans_q.pop_front();
            wait(trans_properties[trans_pointer].valid);

            // Update checker components: Gshare, BTB, RAS
            // while ((pr_queue.size()>0)) begin 
            //     pr_trans = pr_queue.pop_front();
            //     if(pr_trans.valid_jump) begin
            //         utils.gsh_update(pr_trans.orig_pc, pr_trans.jump_taken);
            //         utils.btb_update(pr_trans.orig_pc, pr_trans.jump_address);
            //     end
            // end
            if(trans_properties[trans_pointer].function_call) begin
                utils.ras_push(trans_properties[trans_pointer].function_call_PC);
            end
            if(trans_properties[trans_pointer].invalid_prediction) begin
                utils.btb_invalidate(trans_properties[trans_pointer].restart_PC);
            end
            
            // Calculate current pc and data_out
            current_pc_gr = fetch_second_ins ? next_pc_2 :next_pc_1;
            gr_packet_[0].pc = next_pc_1;
            gr_packet_[1].pc = next_pc_2;
            for (int i = 0; i < INSTR_COUNT; i++) begin
                if(!fetch_second_ins) begin
                    gr_packet_[i].data = trans.Ins_data[i];
                    gr_packet_[i].taken_branch = utils.is_taken(gr_packet_[i].pc);
                end else begin 
                    gr_packet_[1].data = trans.Ins_data[0];
                    gr_packet_[1].taken_branch = utils.is_taken(gr_packet_[1].pc);
                end
            end
            
            valid_o_gr = ~trans_properties[trans_pointer].invalid_instruction & ~trans_properties[trans_pointer].invalid_prediction &
                         ~trans_properties[trans_pointer].function_return & (~gr_packet_[0].taken_branch | (gr_packet_[0].taken_branch & fetch_second_ins));
        
            $display("[GR] @ %0t ps current_pc_gr[%0d]=%0d orig_1=%0d orig_2=%0d",$time(),trans_pointer,current_pc_gr,orig_1,orig_2);
            $display("[GR] @ %0t ps gr_packet_[%0d][0]=%p ",$time(),trans_pointer,gr_packet_[0]);
            $display("[GR] @ %0t ps gr_packet_[%0d][1]=%p ",$time(),trans_pointer,gr_packet_[1]);
            $display("trans_properties[%0d]=%p",trans_pointer,trans_properties[trans_pointer]);
        
            // Save results for report_phase
            gr_array[trans_pointer].current_pc_gr = current_pc_gr;
            for (int i = 0; i < INSTR_COUNT; i++) begin
                gr_array[trans_pointer].packet_[i].pc = gr_packet_[i].pc;
                gr_array[trans_pointer].packet_[i].data = gr_packet_[i].data;
                gr_array[trans_pointer].packet_[i].taken_branch = gr_packet_[i].taken_branch;
            end
            gr_array[trans_pointer].valid_o_gr = valid_o_gr;




            

            // Next pc calculation
            if(trans_properties[trans_pointer].invalid_instruction) begin
                next_pc_1 = trans_properties[trans_pointer].restart_PC;
                next_pc_2 = next_pc_1 + 4;
                fetch_second_ins = 0;
                orig_1 = 0;
            end else if(trans_properties[trans_pointer].invalid_prediction) begin
                next_pc_1 = trans_properties[trans_pointer].restart_PC;
                next_pc_2 = next_pc_1 + 4;
                fetch_second_ins = 0;
                orig_1 = 1;
            end else if((trans_properties[trans_pointer].function_return)&&(utils.ras_queue.size()>0)) begin
                next_pc_1 = utils.ras_pop() + 4;
                next_pc_2 = next_pc_1 + 4;
                fetch_second_ins = 0;
                orig_1 = 2;
            end else begin 
                // Normal operation
                // 1) check if the PC address corresponds to a taken branch (from Gshare)
                // 2) If it is taken, we search for the target address from BTB
                // 3) If BTB hits we grab it else just increment the current pc
                pc_a = gr_packet_[0].pc;
                pc_b = gr_packet_[1].pc;
                is_taken_a = gr_packet_[0].taken_branch;
                is_taken_b = gr_packet_[1].taken_branch;
                if(is_taken_a) begin
                    if(!fetch_second_ins) begin
                        fetch_second_ins = 1;
                        next_pc_1 = pc_a;
                        next_pc_2 = utils.next_PC(pc_a);
                    end else begin 
                        fetch_second_ins = 0;
                        if(is_taken_b) begin
                            next_pc_1 = utils.next_PC(pc_b);
                            next_pc_2 = next_pc_1 + 4;
                        end else begin 
                            next_pc_1 = pc_b + 4;
                            next_pc_2 = next_pc_1 + 4;
                        end
                    end
                end else if(is_taken_b) begin
                    next_pc_1 = utils.next_PC(pc_b);
                    next_pc_2 = next_pc_1 + 4;
                end else begin 
                    next_pc_1 = pc_b + 4;
                    next_pc_2 = next_pc_1 + 4;
                end

            end // else normal operation

            
            

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
        $display("[DUT] @ %0t ps packet_[%0d][0]=%p ",$time(),trans_pointer_synced,dut_array[trans_pointer_synced].packet_[0]);
        $display("[DUT] @ %0t ps packet_[%0d][1]=%p ",$time(),trans_pointer_synced,dut_array[trans_pointer_synced].packet_[1]);
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
    int wrong_valid = 0;
    int correct_valid = 0;

    for (int i = 0; i < TRANS_NUM; i++) begin

      if(dut_array[i].valid_o_gr) begin
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

        if(gr_array[i].valid_o_gr != dut_array[i].valid_o_gr) begin  
          `uvm_error(get_type_name(),$sformatf("[CHECKER] @ %0t ps Expected: gr_array[%0d].valid_o_gr=%0d Recieved:%0d", dut_array[i].sim_time,i,gr_array[i].valid_o_gr,dut_array[i].valid_o_gr))
          wrong_valid++;
        end else begin
          correct_valid++;
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