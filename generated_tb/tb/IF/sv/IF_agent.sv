// You can insert code here by setting file_header_inc in file common.tpl

//=============================================================================
// Project  : generated_tb
//
// File Name: IF_agent.sv
//
//
// Version:   1.0
//
// Code created by Easier UVM Code Generator version 2016-08-11 on Wed Aug  8 13:55:33 2018
//=============================================================================
// Description: Agent for IF
//=============================================================================

`ifndef IF_AGENT_SV
`define IF_AGENT_SV

// You can insert code here by setting agent_inc_before_class in file IF.tpl

class IF_agent extends uvm_agent;

  `uvm_component_utils(IF_agent)

  uvm_analysis_port #(trans) analysis_port;

  IF_config       m_config;
  IF_sequencer_t  m_sequencer;
  icache_driver   m_driver;
  ready_driver    m_ready_driver;
  branch_resolve_driver m_branch_resolve_driver;
  restart_driver  m_restart_driver;
  flush_driver    m_flush_driver;
  IF_monitor      m_monitor;

  local int m_is_active = -1;

  extern function new(string name, uvm_component parent);

  // You can remove build/connect_phase and get_is_active by setting agent_generate_methods_inside_class = no in file IF.tpl

  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern function uvm_active_passive_enum get_is_active();

  // You can insert code here by setting agent_inc_inside_class in file IF.tpl

endclass : IF_agent 


function  IF_agent::new(string name, uvm_component parent);
  super.new(name, parent);
  analysis_port = new("analysis_port", this);
endfunction : new


// You can remove build/connect_phase and get_is_active by setting agent_generate_methods_after_class = no in file IF.tpl

function void IF_agent::build_phase(uvm_phase phase);

  // You can insert code here by setting agent_prepend_to_build_phase in file IF.tpl

  if (!uvm_config_db #(IF_config)::get(this, "", "config", m_config))
    `uvm_error(get_type_name(), "IF config not found")

  m_monitor     = IF_monitor    ::type_id::create("m_monitor", this);

  if (get_is_active() == UVM_ACTIVE)
  begin
    m_driver    = icache_driver ::type_id::create("m_driver", this);
    m_sequencer = IF_sequencer_t::type_id::create("m_sequencer", this);
    m_ready_driver = ready_driver::type_id::create("m_ready_driver", this);
    m_branch_resolve_driver = branch_resolve_driver::type_id::create("m_branch_resolve_driver", this);
    m_restart_driver = restart_driver::type_id::create("m_restart_driver", this);
    m_flush_driver = flush_driver::type_id::create("m_flush_driver", this);
  end

  // You can insert code here by setting agent_append_to_build_phase in file IF.tpl

endfunction : build_phase


function void IF_agent::connect_phase(uvm_phase phase);
  if (m_config.vif == null)
    `uvm_warning(get_type_name(), "IF virtual interface is not set!")

  m_monitor.vif = m_config.vif;
  m_monitor.analysis_port.connect(analysis_port);

  if (get_is_active() == UVM_ACTIVE)
  begin
    m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    m_driver.vif = m_config.vif;
    m_ready_driver.vif = m_config.vif;
    m_branch_resolve_driver.vif = m_config.vif;
    m_restart_driver.vif = m_config.vif;
    m_flush_driver.vif = m_config.vif;
  end

  // You can insert code here by setting agent_append_to_connect_phase in file IF.tpl

endfunction : connect_phase


function uvm_active_passive_enum IF_agent::get_is_active();
  if (m_is_active == -1)
  begin
    if (uvm_config_db#(uvm_bitstream_t)::get(this, "", "is_active", m_is_active))
    begin
      if (m_is_active != m_config.is_active)
        `uvm_warning(get_type_name(), "is_active field in config_db conflicts with config object")
    end
    else 
      m_is_active = m_config.is_active;
  end
  return uvm_active_passive_enum'(m_is_active);
endfunction : get_is_active


// You can insert code here by setting agent_inc_after_class in file IF.tpl

`endif // IF_AGENT_SV

