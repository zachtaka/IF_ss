agent_name = IF
trans_item = trans

if_clock = logic clk;
if_port  = logic rst_n;

if_port = logic [2*PACKET_SIZE-1:0] data_out;
if_port = logic                     valid_o;
if_port = logic                     ready_in;
if_port = logic                     is_branch;
if_port = logic predictor_update    pr_update;
if_port = logic                     invalid_instruction;
if_port = logic                     invalid_prediction;
if_port = logic                     is_return_in;
if_port = logic                     is_jumpl;
if_port = logic [PC_BITS-1:0]       old_PC;
if_port = logic                     must_flush;
if_port = logic [PC_BITS-1:0]       correct_address;
if_port = logic [PC_BITS-1:0]       current_PC;
if_port = logic                     Hit_cache;
if_port = logic                     Miss;
if_port = logic                     partial_access;
if_port = logic [1:0]               partial_type;
if_port = logic [FETCH_WIDTH-1:0]   fetched_data;