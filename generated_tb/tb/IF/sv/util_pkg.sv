package util_pkg;

// DUT parameters

parameter int PACKET_SIZE = 65;// from processor_top:  $bits(dummy_fetched_packet) = pc_bits(32)+data(32)+taken_branch(1)
parameter int PC_BITS = 32;
parameter int FETCH_WIDTH = 64;
parameter int INSTR_BITS = 32;
parameter int RAS_DEPTH = 8;
parameter int GSH_HISTORY_BITS = 2;
parameter int GSH_SIZE = 256;
parameter int BTB_SIZE = 256;

// TB simulation parameters
parameter int TRANS_NUM = 100; // Number of transactions that will be sent from to sequencer to the icache driver
parameter int ICACHE_MISS_RATE = 0; // The rate of misses from the icache driver, valid range:[0,99]
parameter int ICACHE_PARTIAL_ACCESS_RATE = 0; // The rate of partial access from icache driver, valid range:[0,100]
parameter int ID_NOT_READY_RATE = 0; // The rate of stall cycle injection from the next pipeline stage, valid range:[0,99]
parameter int INS_BRANCH_RATE = 25;
parameter int BACK_BRANCH_RATE = 50;
parameter int BACK_BRANCH_IS_TAKEN_RATE =75;
parameter int FORW_BRANCH_IS_TAKEN_RATE = 50;
// parameter int MIN_BACK_BRANCH_JUMP_RANGE = 0;
// parameter int MAX_BACK_BRANCH_JUMP_RANGE = 0;



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
  bit is_return_in;
  bit is_jumpl;
  // Flush
  bit flushed;
} monitor_DUT_s;


typedef struct packed {
    logic [31 : 0] pc          ;
    logic [31 : 0] data        ;
    logic          taken_branch;
} fetched_packet;


typedef struct packed {
  bit [PC_BITS-1:0] current_pc_gr;
  fetched_packet[INSTR_COUNT-1:0] packet_;
  longint sim_time;
} output_array_s;

endpackage