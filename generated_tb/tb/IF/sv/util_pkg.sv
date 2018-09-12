package util_pkg;

/*----------- DUT parameters -----------*/
parameter int PACKET_SIZE = 65;// from processor_top:  $bits(dummy_fetched_packet) = pc_bits(32)+data(32)+taken_branch(1)
parameter int PC_BITS = 32;
parameter int FETCH_WIDTH = 64;
parameter int INSTR_BITS = 32;
parameter int RAS_DEPTH = 8;
parameter int GSH_HISTORY_BITS = 2;
parameter int GSH_SIZE = 256;
parameter int BTB_SIZE = 256;

/*----------- TB simulation parameters -----------*/
parameter int TRANS_NUM = 10000; // Number of transactions that will be sent from to sequencer to the icache driver
// Ins mapping parameters 
parameter int INS_BRANCH_RATE = 40; // Rate of branch instructions
parameter int BACK_BRANCH_RATE = 50; // Rate of branch instructions that will be considered as backwards branch
parameter int BACK_BRANCH_IS_TAKEN_RATE = 80;
parameter int FORW_BRANCH_IS_TAKEN_RATE = 50;
// Icache parameters
parameter int ICACHE_MISS_RATE = 20; // The rate of misses from the icache driver, valid range:[0,99]
parameter int ICACHE_PARTIAL_ACCESS_RATE = 20; // The rate of partial access from icache driver, valid range:[0,100]
// ID parameters
parameter int ID_NOT_READY_RATE = 0; // The rate of stall cycle injection from the next pipeline stage, valid range:[0,99]
// Restart parameters
parameter int INVALID_INS_RATE = 30; 
parameter int INVALID_PREDICTION_RATE = 30;
parameter int FUNCTION_CALL_RATE = 0;
parameter int FUNCTION_RETURN_RATE = 0;
// Flush parameter
parameter int FLUSH_RATE = 5;


// TB structure parameters
parameter int INSTR_COUNT = 2; // extra parameter
parameter int GSH_COUNTER_NUM = 4;


// Structs
typedef struct packed {
  logic          valid_jump  ;
  logic          jump_taken  ;
  logic          is_comp     ;
  logic [ 1 : 0] rat_id      ;
  logic [31 : 0] orig_pc     ;
  logic [31 : 0] jump_address;
  logic [ 2 : 0] ticket      ;
} predictor_update;

typedef struct packed {
  predictor_update pr_update;
  bit skip_btb;
} predictor_update_extended;

typedef struct packed {
  bit[PC_BITS-1:0]  orig_pc;
  bit[PC_BITS-1:0]  target_pc;
  bit               valid;
} btb_array_entry_s;

typedef struct packed {
  bit[PC_BITS-1:0] target_pc;
  bit hit;
} btb_read_s;

typedef struct packed {
  // Restart
  bit invalid_instruction;
  bit invalid_prediction;
  // Functions
  bit function_call;
  bit [PC_BITS-1:0] function_call_PC;
  bit function_return;
  // Flush
  bit flushed;
  bit valid;
  bit[PC_BITS-1:0] restart_PC, flush_PC;

  bit skip_last_cycle_pr_update;
  bit skip_btb_update;

  bit partial_access;
  bit[1:0] partial_type;
} monitor_DUT_s;


typedef struct packed {
    logic [31 : 0] pc          ;
    logic [31 : 0] data        ;
    logic          taken_branch;
} fetched_packet;


typedef struct packed {
  bit [PC_BITS-1:0] current_pc_gr;
  fetched_packet[INSTR_COUNT-1:0] packet_;
  bit valid_o_gr;
  longint sim_time;
} output_array_s;

typedef struct packed {
  // Restart
  bit invalid_instruction;
  bit invalid_prediction;
  // Functions
  bit function_call;
  bit function_return;
  // Flush
  bit flushed;
  bit[PC_BITS-1:0] restart_PC, flush_PC;
} restart_s;

typedef struct packed {
  int cycle;
  predictor_update pr_update;
  bit pr_valid;
  bit pr_exec;
  restart_s restart;
  bit rst_valid;
  bit rst_exec;
  bit valid_entry;
} event_entry_s;



endpackage