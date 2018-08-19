`ifndef Checker_sv
`define Checker_sv

import util_pkg::*;
class Checker extends uvm_subscriber #(trans);
  `uvm_component_utils(Checker)

  virtual IF_if vif;
  Checker_utils utils;

  int current_pc_gr, next_pc;
  fetched_packet[INSTR_COUNT-1:0] gr_packet_, dut_packet_;
  bit [INSTR_COUNT*(PC_BITS+INSTR_BITS+1)-1:0] data_out_gr;
  output_array_s [TRANS_NUM-1:0] gr_array, dut_array;
  int trans_pointer=0;

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name,parent);
    utils = new();
    current_pc_gr = 0;
    next_pc = 0;
  endfunction


  function void write(trans t);
    // Calculate current pc and data_out
    current_pc_gr = next_pc;
    for (int i = 0; i < INSTR_COUNT; i++) begin
      gr_packet_[i].pc = current_pc_gr + i*(PC_BITS/8);
      gr_packet_[i].data = t.Ins_data[i];
      gr_packet_[i].taken_branch = utils.gsh_read(current_pc_gr);
    end
    // $display("@ %0t ps trans_pointer=%0d data_0=%0d data_1=%0d",$time(),trans_pointer,t.Ins_data[0],t.Ins_data[1]);
    // data_out_gr = {gr_packet_[1],gr_packet_[0]};
    // $display("data_out=%0d",data_out_gr);

    // Save results for report_phase
    gr_array[trans_pointer].current_pc_gr = current_pc_gr;
    for (int i = 0; i < INSTR_COUNT; i++) begin
      gr_array[trans_pointer].packet_[i].pc = gr_packet_[i].pc;
      gr_array[trans_pointer].packet_[i].data = gr_packet_[i].data;
      gr_array[trans_pointer].packet_[i].taken_branch = gr_packet_[i].taken_branch;
    end
    // gr_array[trans_pointer].data_out_gr = data_out_gr;


    next_pc = next_pc + INSTR_COUNT*(PC_BITS/8);

    trans_pointer++;
  endfunction


  monitor_DUT_s [TRANS_NUM-1:0] trans_properties;
  task monitor_DUT();
    int trans_pointer = 0;
    forever begin 
      if(vif.valid_o && vif.ready_in) begin
        dut_array[trans_pointer].current_pc_gr = vif.current_PC;
        {dut_array[trans_pointer].packet_[1],dut_array[trans_pointer].packet_[0]} = vif.data_out;
        dut_array[trans_pointer].sim_time = $time();
        // dut_array[trans_pointer]. = vif.data_out;
        // $display("vif.data_out = %0d",vif.data_out);
      end

      if(vif.valid_o) begin
        if(vif.invalid_instruction) trans_properties[trans_pointer].invalid_instruction = 1;
        if(vif.invalid_prediction)  trans_properties[trans_pointer].invalid_prediction = 1;
        if(vif.is_return_in)        trans_properties[trans_pointer].is_return_in = 1;
        if(vif.is_jumpl)            trans_properties[trans_pointer].is_jumpl = 1;
        if(vif.must_flush)          trans_properties[trans_pointer].flushed = 1;
      end

      if(vif.valid_o && vif.ready_in) begin
        trans_pointer++;
      end

      @(negedge vif.clk);
    end
  
  endtask

  task run_phase(uvm_phase phase);
    monitor_DUT();
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
        `uvm_error(get_type_name(),$sformatf("[CHECKER] @ %0t ps Expected: current_pc_gr=%0d Recieved:%0d", dut_array[i].sim_time,gr_array[i].current_pc_gr,dut_array[i].current_pc_gr))
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