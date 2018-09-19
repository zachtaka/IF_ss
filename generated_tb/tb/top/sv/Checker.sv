`ifndef Checker_sv
`define Checker_sv

import util_pkg::*;
import drivers_pkg::*;
class Checker extends uvm_subscriber #(trans);
  `uvm_component_utils(Checker)

  virtual IF_if vif;
  Checker_utils utils;
  output_array_s [TRANS_NUM-1:0] gr_array, dut_array;
  trans trans_q[$];
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name,parent);
    utils = new();
  endfunction

  // Gets fetched data from icache driver
  // Each fetch from the icache is considered as a transaction item
  function void write(trans t);
    trans_q.push_back(t);
  endfunction


  
  
  

  task GR_model();
    trans trans;
    monitor_DUT_s transaction_properties;
    bit invalid_instruction, invalid_prediction, function_return, restart_issued, flush_issued, is_taken_a, is_taken_b, skip_pr;
    bit partial_access, partial_access_fsm, half_access_fsm;
    bit [1:0] partial_type, partial_type_saved;
    bit [FETCH_WIDTH-1:0] partial_data_saved;
    int restart_PC, flush_PC, pc_a, pc_b, trans_pointer, current_pc_gr;
    fetched_packet[INSTR_COUNT-1:0] gr_packet_;
    int next_pc_1=0; 
    int next_pc_2=4;


    forever begin 
        if(trans_q.size()>0) begin
            trans = trans_q.pop_front();
            wait(trans_properties[trans_pointer].valid);
            $display("\n[CHECKER] @ %0t ps START trans=%0d",$time(),trans_pointer);

            // Transaction properties setting
            transaction_properties = trans_properties[trans_pointer];
            // Partial access properties
            partial_access = transaction_properties.partial_access;
            partial_type   = transaction_properties.partial_type;
            // Restart properties
            invalid_instruction = transaction_properties.invalid_instruction;
            invalid_prediction  = transaction_properties.invalid_prediction;
            function_return     = transaction_properties.function_return;
            restart_PC          = transaction_properties.restart_PC;
            restart_issued      = invalid_instruction|invalid_prediction|function_return;
            // Flush properties
            flush_issued = transaction_properties.flushed;
            flush_PC     = transaction_properties.flush_PC;


            $display("[CHECKER] @ %0t ps Installing Predictor updates",$time());
            skip_pr = transaction_properties.skip_last_cycle_pr_update;
            utils.get_pr_updates(skip_pr);
            
            
            $display("[CHECKER] @ %0t ps Running GR model",$time());
            // Current pc GR
            current_pc_gr = (partial_access_fsm||half_access_fsm) ? next_pc_2:next_pc_1;
            // Packet pc GR
            gr_packet_[0].pc = next_pc_1;
            gr_packet_[1].pc = next_pc_2;
            // Packet data GR
            if(half_access_fsm) begin
              gr_packet_[1].data = trans.data[FETCH_WIDTH/2-1:0];
            end else if(partial_access_fsm) begin
              if(partial_type_saved==1) begin
                {gr_packet_[1].data,gr_packet_[0].data} = {trans.data[FETCH_WIDTH*3/4-1:0], partial_data_saved[FETCH_WIDTH/4-1:0]};
              end else if(partial_type_saved==2) begin 
                {gr_packet_[1].data,gr_packet_[0].data} = {trans.data[FETCH_WIDTH/2-1:0], partial_data_saved[FETCH_WIDTH/2-1:0]};
              end else if(partial_type_saved==3) begin
                {gr_packet_[1].data,gr_packet_[0].data} = {trans.data[FETCH_WIDTH/4-1:0], partial_data_saved[FETCH_WIDTH*3/4-1:0]};
              end
            end else begin 
              {gr_packet_[1].data,gr_packet_[0].data} = trans.data;
            end

            // Packet taken branch GR
            if((!half_access_fsm)&&(!(partial_access_fsm))) begin
                gr_packet_[0].taken_branch = utils.is_taken(gr_packet_[0].pc);
                gr_packet_[1].taken_branch = utils.is_taken(gr_packet_[1].pc);
            end else begin 
                gr_packet_[1].taken_branch = utils.is_taken(gr_packet_[1].pc);
            end
            
          
            $display("[GR] @ %0t ps current_pc_gr[%0d]=%0d (partial_access_fsm=%b, half_access_fsm=%b)",$time(),trans_pointer,current_pc_gr,partial_access_fsm,half_access_fsm);
            $display("[GR] @ %0t ps gr_packet_[%0d][0]=%p ",$time(),trans_pointer,gr_packet_[0]);
            $display("[GR] @ %0t ps gr_packet_[%0d][1]=%p ",$time(),trans_pointer,gr_packet_[1]);
        
            
            // Next pc calculation
            $display("[CHECKER] @ %0t ps Calculating next pc's",$time());
            pc_a = gr_packet_[0].pc;
            pc_b = gr_packet_[1].pc;
            is_taken_a = gr_packet_[0].taken_branch;
            is_taken_b = gr_packet_[1].taken_branch;
            if(restart_issued||flush_issued) begin
              {next_pc_2,next_pc_1} = utils.get_next_pc_restart(flush_issued,invalid_instruction,invalid_prediction,function_return,flush_PC,restart_PC);
            end else begin 
              {next_pc_2,next_pc_1} = utils.get_next_pc_normal(is_taken_a,is_taken_b,half_access_fsm,partial_access,pc_a,pc_b,next_pc_1,next_pc_2);
            end 
            
         
            // Partial access 
            if(partial_access) begin
              partial_type_saved = partial_type;
              if(partial_type==1) begin
                partial_data_saved = {{48{1'b0}},trans.data[FETCH_WIDTH/4-1:0]};
              end else if(partial_type==2) begin 
                partial_data_saved = {{32{1'b0}},trans.data[FETCH_WIDTH/2-1:0]};
              end else if(partial_type==3) begin
                partial_data_saved = {{16{1'b0}},trans.data[FETCH_WIDTH*3/4-1:0]};
              end
            end

            // Partial access fsm
            if(!partial_access_fsm) begin
              if(partial_access) begin
                if(!is_taken_a) begin
                  partial_access_fsm = (!restart_issued)&&(!flush_issued);
                end
              end
            end else if(partial_access_fsm) begin
              partial_access_fsm = 0;
            end
            $display("partial_access_fsm[%0d]=%0d",trans_pointer,partial_access_fsm);
            
            // Half access fsm
            if(!half_access_fsm) begin
              if(is_taken_a) begin
                half_access_fsm = (!restart_issued)&&(!flush_issued);
              end
            end else if(half_access_fsm) begin
              half_access_fsm = 0;
            end
            $display("half_access_fsm[%0d]=%0d",trans_pointer,half_access_fsm);
            


            if(transaction_properties.function_call)      utils.ras_push(trans_properties[trans_pointer].function_call_PC);
            if(transaction_properties.invalid_prediction) utils.btb_invalidate(transaction_properties.restart_PC, transaction_properties.pr_after_btb_inv);
            


            // Save results for report_phase
            gr_array[trans_pointer].current_pc_gr = current_pc_gr;
            for (int i = 0; i < INSTR_COUNT; i++) begin
                gr_array[trans_pointer].packet_[i].pc           = gr_packet_[i].pc;
                gr_array[trans_pointer].packet_[i].data         = gr_packet_[i].data;
                gr_array[trans_pointer].packet_[i].taken_branch = gr_packet_[i].taken_branch;
            end

            $display("[CHECKER] @ %0t ps END\n",$time());
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
      end
      @(negedge vif.clk);
    end
  
  endtask

  task monitor_trans_properties();
    bit half_access, partial_access;
    fetched_packet packet_a, packet_b;
    predictor_update_extended pr_item;
    forever begin 

      // If predictor update came the last cycle before new pc pointer issued to Icache 
      // then skip this update at the calculation of GR model for this transaction
      if(vif.pr_update.valid_jump) begin
        {packet_b,packet_a} = vif.data_out;
        half_access = packet_a.taken_branch&&(!vif.valid_o)&&vif.Hit_cache;
        partial_access = vif.partial_access&&vif.Hit_cache;
        if((vif.valid_o&&vif.ready_in)||half_access||partial_access) begin
          trans_properties[trans_pointer_synced].skip_last_cycle_pr_update = 1;
        end
      end

      if(vif.pr_update.valid_jump) begin
        pr_item.pr_update = vif.pr_update;
        // If invalid prediction and predictor update issued at the same cycle for the same orig pc then dont update btb entry
        pr_item.skip_btb  = vif.invalid_prediction&&(vif.old_PC==vif.pr_update.orig_pc);
        // New predictor update came after a btb invalidation
        trans_properties[trans_pointer_synced].pr_after_btb_inv = trans_properties[trans_pointer_synced].invalid_prediction&&(pr_item.pr_update.orig_pc==trans_properties[trans_pointer_synced].restart_PC);
        utils.pr_queue.push_back(pr_item);
      end

      // Restart properties
      // Invalid instruction
      if(vif.invalid_instruction) begin 
         trans_properties[trans_pointer_synced].invalid_instruction = 1;
         trans_properties[trans_pointer_synced].restart_PC          = vif.old_PC;
      end
      // Invalid prediction
      if(vif.invalid_prediction) begin 
        trans_properties[trans_pointer_synced].invalid_prediction = 1;
        trans_properties[trans_pointer_synced].restart_PC         = vif.old_PC;
      end
      // Function return
      if(vif.is_return_in) begin 
        trans_properties[trans_pointer_synced].function_return = 1;
      end
      // Function call
      if(vif.is_jumpl) begin 
        trans_properties[trans_pointer_synced].function_call    = 1;
        trans_properties[trans_pointer_synced].function_call_PC = vif.old_PC;
      end
      // Pipeline flush
      if(vif.must_flush) begin 
        trans_properties[trans_pointer_synced].flushed  = 1;
        trans_properties[trans_pointer_synced].flush_PC = vif.correct_address;
      end


      // Partial access properties
      if(vif.partial_access) begin
        trans_properties[trans_pointer_synced].partial_access = 1;
        trans_properties[trans_pointer_synced].partial_type   = vif.partial_type;
      end
      

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
    int correct_pc, wrong_pc;
    int correct_pc2, wrong_pc2;
    int correct_data, wrong_data;
    int correct_branch_taken, wrong_branch_taken;

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
        end //for
          
      end //if

    end //for

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