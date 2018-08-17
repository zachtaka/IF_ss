import util_pkg::*;
class Checker_utils;

  // Gshare Predictor
  bit [GSH_SIZE-1:0][GSH_COUNTER_NUM*2-1:0] gshare_array;
  bit [GSH_HISTORY_BITS-1:0] gsh_history;
  // Branch Target Buffer (BTB)
  btb_array_entry_s [BTB_SIZE-1:0] btb_array;
  // Return Address Stack (RAS)
  bit[PC_BITS-1:0] ras_queue [$:RAS_DEPTH-1];


  // Initialize Checker components
  function new();

  endfunction 


  /*
  // Gshare Predictor
  */
  function bit[1:0] update_counter_value (bit is_taken, bit[1:0] old_counter_value);
    bit[1:0] new_counter_value;

    if(is_taken) begin
      if(old_counter_value<2'b11) new_counter_value = old_counter_value+1;
    end else begin
      if(old_counter_value>2'b00) new_counter_value = old_counter_value-1;
    end
    return new_counter_value;
  endfunction 

  function void gsh_update(input int pc, bit is_taken);
    int line, counter_id;

    // update counter value
    line = pc[$clog2(GSH_SIZE):1];
    counter_id = pc[GSH_HISTORY_BITS:1] ^ gsh_history;
    gshare_array[line][counter_id*2+:2] = update_counter_value(is_taken, gshare_array[line][counter_id*2+:2]);
    //update gsh history
    gsh_history = {is_taken, gsh_history[GSH_HISTORY_BITS-1:1]};
  endfunction 

  function bit gsh_read(input int pc);
    int line, counter_id;
    bit[1:0] counter_value;
    bit is_taken;

    line = pc[$clog2(GSH_SIZE):1];
    counter_id = pc[GSH_HISTORY_BITS:1] ^ gsh_history;
    counter_value = gshare_array[line][(counter_id*2)+:2];

    is_taken = counter_value>1;
    return is_taken;
  endfunction

  /*
  // Branch Target Buffer (BTB)
  */
  function void btb_update(input int orig_pc, input int target_pc);
    int line;

    line = orig_pc[$clog2(BTB_SIZE):1];
    btb_array[line].orig_pc = orig_pc;
    btb_array[line].target_pc = target_pc;
    btb_array[line].valid = 1;
  endfunction

  function btb_read_s btb_read(input int pc);
    btb_read_s btb;
    int line;

    line = pc[$clog2(BTB_SIZE):1];
    btb.target_pc = btb_array[line].target_pc;
    btb.hit = (pc==btb_array[line].orig_pc)&(btb_array[line].valid);

    return btb;
  endfunction


  /*
  // Return Address Stack (RAS)
  */
  function void ras_push(input int pc);
    ras_queue.push_back(pc);
  endfunction

  function bit[PC_BITS-1:0] ras_pop();
    bit[PC_BITS-1:0] return_pc; 
    return_pc = ras_queue.pop_front();
    return return_pc;
  endfunction

endclass : Checker_utils