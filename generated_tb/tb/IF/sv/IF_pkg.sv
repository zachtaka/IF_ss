package IF_pkg;

  `include "uvm_macros.svh"

  import uvm_pkg::*;


  `include "IF_trans.sv"
  `include "IF_config.sv"
  `include "drivers/icache_driver.sv"
  `include "drivers/ready_driver.sv"
  `include "drivers/branch_resolve_driver.sv"
  `include "drivers/restart_driver.sv"
  `include "drivers/flush_driver.sv"
  `include "IF_monitor.sv"
  `include "IF_sequencer.sv"
  `include "IF_coverage.sv"
  `include "IF_agent.sv"
  `include "IF_seq_lib.sv"

endpackage : IF_pkg
