`ifndef IF_IF_SV
`define IF_IF_SV

import util_pkg::*;

interface IF_if(); 

  timeunit      1ns;
  timeprecision 1ps;

  import IF_pkg::*;

  logic clk;
  logic rst_n;
  logic [2*PACKET_SIZE-1:0] data_out;
  logic                     valid_o;
  logic                     ready_in;
  logic                     is_branch;
  predictor_update          pr_update;
  logic                     invalid_instruction;
  logic                     invalid_prediction;
  logic                     is_return_in;
  logic                     is_jumpl;
  logic [PC_BITS-1:0]       old_PC;
  logic                     must_flush;
  logic [PC_BITS-1:0]       correct_address;
  logic [PC_BITS-1:0]       current_PC;
  logic                     Hit_cache;
  logic                     Miss;
  logic                     partial_access;
  logic [1:0]               partial_type;
  logic [FETCH_WIDTH-1:0]   fetched_data;

  int                       trans_id_dbg;


  /*----------- Assertion properties -----------*/
  // All restart signals that belong to the low tier(inv prediction, inv instruction, function return) are mutually exclusive
  // only one can be active at each cycle
  xor_restarts: assert property (@(posedge clk) disable iff(!rst_n) (invalid_prediction||invalid_instruction||is_return_in) |-> ^{invalid_prediction,invalid_instruction,is_return_in})
                else $fatal("Illegal to have more than one restart request");

  // Valid/Ready protocol
  Valid_stable: assert property (@(posedge clk) disable iff(!rst_n) (valid_o && !ready_in) |=> $stable(data_out))
                else $fatal("Data out changed while valid was asserted and ready was low");
  

  // Tb structure assertion: Check that current pc point to a mapped Instruction of icache driver
  Ins_not_mapped: assert property (@(posedge clk) disable iff (!rst_n) 1'b1 |-> (current_PC < TRANS_NUM*8))
                  else $fatal("Instruction out of icache driver memory bounds (current pc=%0d > upper bound=%0d)",current_PC,TRANS_NUM*INSTR_COUNT*2);

  // ------------------------   Cover properties  --------------------------
  /*----------- Corner cases -----------*/
  // Issue of invalid prediction (btb invalidation) and predictor update for the same pc at the same cycle
  btb_invalid_and_pr_update_samePC: cover property (@(posedge clk) disable iff(!rst_n) invalid_prediction |-> (pr_update.valid_jump&&(pr_update.orig_pc==old_PC)));
  
  // Partial access of type 1(16 valid bits) and branch 1 is taken
  // IF should fetch the remaining 16 bits of 1st instruction and then fetch the target pc as second instruction
  fetched_packet packet_a, packet_b;
  assign {packet_b,packet_a} = data_out;
  partial_access_type1_branch: cover property (@(posedge clk) disable iff(!rst_n) 1'b1 |-> partial_access&&(partial_type==1)&&Hit_cache&&(packet_a.taken_branch==1));

  // Partial access of type 2(32 valid bits) and branch 1 is taken
  // IF should fetch the target pc as second instruction
  partial_access_type2_branch: cover property (@(posedge clk) disable iff(!rst_n) 1'b1 |-> partial_access&&(partial_type==2)&&Hit_cache&&(packet_a.taken_branch==1));

  // Partial access of type 3(32 valid bits) and branch 1 is taken
  // IF should fetch the target pc as second instruction
  partial_access_type3_branch: cover property (@(posedge clk) disable iff(!rst_n) 1'b1 |-> partial_access&&(partial_type==3)&&Hit_cache&&(packet_a.taken_branch==1));

  /*----------- IF restart FSM scenarios -----------*/
  // Invalid instruction while fsm is blocked
  invalid_instruction_while_icache_blocked: cover property (@(posedge clk) disable iff(!rst_n) invalid_instruction |-> Miss);
  
  // Invalid prediction while fsm is blocked
  invalid_prediction_while_icache_blocked: cover property (@(posedge clk) disable iff(!rst_n) invalid_prediction |-> Miss);
  
  // Flush while fsm is blocked
  flush_while_icache_blocked: cover property (@(posedge clk) disable iff(!rst_n) must_flush |-> Miss);
  
  // Flush & invalid instruction issued while fsm is blocked
  flush_inv_ins_while_icache_blocked: cover property (@(posedge clk) disable iff(!rst_n) must_flush |-> (invalid_instruction&&Miss));
  
  // Flush & invalid prediction issued while fsm is blocked
  flush_inv_pred_while_icache_blocked: cover property (@(posedge clk) disable iff(!rst_n) must_flush |-> (invalid_prediction&&Miss));
  
  // Flush & function return issued while fsm is blocked
  flush_fnc_ret_while_icache_blocked: cover property (@(posedge clk) disable iff(!rst_n) must_flush |-> (is_return_in&&Miss));
  
  

  /*----------- Invalid instruction issue scenarios -----------*/
  // How many invalid instructions issued
  invalid_instructions: cover property (@(posedge clk) disable iff(!rst_n) 1'b1 |-> invalid_instruction);

  // Invalid instruction issued while icache hit
  invalid_instructions_at_hit: cover property (@(posedge clk) disable iff(!rst_n) invalid_instruction |-> Hit_cache);

  // Invalid instruction issued while icache miss
  invalid_instructions_at_miss: cover property (@(posedge clk) disable iff(!rst_n) invalid_instruction |-> Miss);

  // Invalid instruction issued while flush issued
  invalid_instructions_at_flus: cover property  (@(posedge clk) disable iff(!rst_n) invalid_instruction |-> must_flush);


  /*----------- Invalid prediction issue scenarios -----------*/
  // How many invalid predictions
  invalid_predictions: cover property (@(posedge clk) disable iff(!rst_n) 1'b1 |-> invalid_prediction);

  // Invalid prediction issued while icache hit
  invalid_predictions_at_hit: cover property (@(posedge clk) disable iff(!rst_n) invalid_prediction |-> Hit_cache);

  // Invalid prediction issued while icache miss
  invalid_predictions_at_miss: cover property (@(posedge clk) disable iff(!rst_n) invalid_prediction |-> Miss);

  // Invalid prediction issued while flush issued
  invalid_predictions_at_flush: cover property (@(posedge clk) disable iff(!rst_n) invalid_prediction |-> must_flush);

  /*----------- Flush issue scenarios -----------*/
  // How many flushes issued
  flushes: cover property (@(posedge clk) disable iff(!rst_n) 1'b1 |-> must_flush);

  // Flush while Hit
  flush_at_hit: cover property (@(posedge clk) disable iff(!rst_n) must_flush |-> Hit_cache);

  // Flush while Miss
  flush_at_miss: cover property (@(posedge clk) disable iff(!rst_n) must_flush |-> Miss);

  // Flush while stall
  flush_at_stall: cover property (@(posedge clk) disable iff(!rst_n) must_flush |-> (valid_o & (~ready_in)));

  /*----------- Function scenarios -----------*/
  // How many function calls
  function_call: cover property (@(posedge clk) disable iff(!rst_n) 1'b1 |-> is_jumpl);

  // How many function returns
  function_return: cover property (@(posedge clk) disable iff(!rst_n) 1'b1 |-> is_return_in);

  /*----------- Partial access -----------*/
  // Icache issued partial access of type 1
  partial_access_type1: cover property (@(posedge clk) disable iff(!rst_n) 1'b1 |-> partial_access&(partial_type==1)&Hit_cache);

  // Icache issued partial access of type 2
  partial_access_type2: cover property (@(posedge clk) disable iff(!rst_n) 1'b1 |-> partial_access&(partial_type==2)&Hit_cache);

  // Icache issued partial access of type 3
  partial_access_type3: cover property (@(posedge clk) disable iff(!rst_n) 1'b1 |-> partial_access&(partial_type==3)&Hit_cache);

  

  // #todo add to coverage not here 
  // Half access and partial access at the target pc
  // Branch 1 is taken and at the fetch of the target pc partial access is issued
  // property half_access_partial_type1;
  //   @(posedge clk) disable iff(!rst_n)
  //   1'b1 |-> partial_access&(partial_type==3)&Hit_cache&(packet_a.taken_branch==1);
  // endproperty

endinterface : IF_if

`endif 

