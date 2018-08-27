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
  int gs_fl;
  int btb_fl;
  function new();
    gs_fl = $fopen("GShare.txt");
    btb_fl = $fopen("BTB.txt");
  endfunction 


  /*
  // Gshare Predictor
  */
  function bit[1:0] update_counter_value (bit is_taken, bit[1:0] old_counter_value);
    bit[1:0] new_counter_value;

    if(is_taken) begin
      if(old_counter_value<2'b11) begin 
        new_counter_value = old_counter_value+1;
      end else begin 
        new_counter_value = old_counter_value;
      end
    end else begin
      if(old_counter_value>2'b00) begin 
        new_counter_value = old_counter_value-1;
      end else begin 
        new_counter_value = old_counter_value;
      end
    end
    return new_counter_value;
  endfunction 

  function void gsh_update(input int pc, bit is_taken);
    int line, counter_id;
    int cnt_value_before;// #todo remove this
    // update counter value
    line = pc[$clog2(GSH_SIZE):1];
    counter_id = pc[GSH_HISTORY_BITS:1] ^ gsh_history;
    cnt_value_before = gshare_array[line][counter_id*2+:2];
    gshare_array[line][counter_id*2+:2] = update_counter_value(is_taken, gshare_array[line][counter_id*2+:2]);
    //update gsh history
    gsh_history = {is_taken, gsh_history[GSH_HISTORY_BITS-1:1]};
    $fdisplay(gs_fl,"[GSHARE] @ %0t ps updt counter, pc=%0d, line=%3d, cnt_id=%0d, is_taken=%0d, cnt_value_before=%0d, cnt_value_after=%0d history_after=%0d",$time(),pc,line,counter_id,is_taken,cnt_value_before,gshare_array[line][counter_id*2+:2],gsh_history);
  endfunction 

  function bit gsh_read(input int pc);
    int line, counter_id;
    bit[1:0] counter_value;
    bit is_taken;

    line = pc[$clog2(GSH_SIZE):1];
    counter_id = pc[GSH_HISTORY_BITS:1] ^ gsh_history;
    counter_value = gshare_array[line][(counter_id*2)+:2];

    is_taken = counter_value>1;

    $fdisplay(gs_fl,"[GSHARE] @ %0t ps read counter, pc=%0d, line=%0d, cnt_id=%0d, is_taken=%0d, cnt_value=%0d, history=%0d",$time(),pc,line,counter_id,is_taken,counter_value,gsh_history);
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
    $fdisplay(btb_fl,"[BTB] pc=%0d, orig_pc=%0d, btb.valid=%b",pc,btb_array[line].orig_pc,btb_array[line].valid);
    $fdisplay(btb_fl,"[BTB] @ %0t ps pc=%0d btb_hit=%b target_pc=%0d",$time(),pc,btb.hit,btb.target_pc);
    return btb;
  endfunction

  function void btb_invalidate(input int pc);
    int line;

    line = pc[$clog2(BTB_SIZE):1];
    btb_array[line].valid = 0;
  endfunction


  /*
  // Return Address Stack (RAS)
  */
  function void ras_push(input int pc);
    if(ras_queue.size()==RAS_DEPTH) ras_queue = ras_queue[0:$-1]; // if overflow delete last item
    ras_queue.push_front(pc);
    // $display("[RAS] pushed:%0d, queue_size(after push)=%0d, queue=%p",pc,ras_queue.size(),ras_queue);
  endfunction

  function bit[PC_BITS-1:0] ras_pop();
    bit[PC_BITS-1:0] return_pc; 
    assert(ras_queue.size()>0) else $fatal("popping from empty ras?");
    return_pc = ras_queue.pop_front();
    // $display("[RAS] popped:%0d, queue_size(after pop)=%0d, queue=%p",return_pc,ras_queue.size(),ras_queue);
    return return_pc;
  endfunction

  /*
  // Checker general functions
  */
  // Combines Gshare and BTB to determine if input pc is taken
  function bit is_taken(input int pc);
    btb_read_s btb;
    bit taken;

    btb = btb_read(pc);
    taken = (gsh_read(pc)&btb.hit);
    return taken;
  endfunction 

  function bit[PC_BITS-1:0] next_PC(input int pc);
    btb_read_s btb;
    bit[PC_BITS-1:0] new_pc;

    if(is_taken(pc)) begin
      btb = btb_read(pc);
      new_pc = btb.target_pc;
    end else begin 
      new_pc = pc + 4;
    end
    return new_pc;
  endfunction

endclass : Checker_utils