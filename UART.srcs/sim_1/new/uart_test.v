`timescale 1ns / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

// ---------------------------------------------------------
// Master Regression Test (Default: Corner Cases + Random)
// ---------------------------------------------------------
class uart_test extends uvm_test;
  `uvm_component_utils(uart_test)

  uart_env env;
  uart_sequence seq;

  function new(string name = "uart_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = uart_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    // Set drain time (100us) to ensure the RX engine finishes the last packet
    phase.phase_done.set_drain_time(this, 100_000);

    `uvm_info("TEST", "Starting Master UART Test...", UVM_LOW)
    seq = uart_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);

    phase.drop_objection(this);
  endtask

endclass

// ---------------------------------------------------------
// Specialized Random Test
// ---------------------------------------------------------
class uart_rand_test extends uvm_test;
  `uvm_component_utils(uart_rand_test)

  uart_env env;
  uart_random_sequence rand_seq;

  function new(string name = "uart_rand_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = uart_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    phase.phase_done.set_drain_time(this, 100_000);

    `uvm_info("RAND_TEST", "Starting 50-packet Random Test...", UVM_LOW)
    rand_seq = uart_random_sequence::type_id::create("rand_seq");
    rand_seq.num_transactions = 50;
    rand_seq.start(env.agent.sequencer);

    phase.drop_objection(this);
  endtask

endclass

// ---------------------------------------------------------
// Specialized Corner-Case Test
// ---------------------------------------------------------
class uart_corner_test extends uvm_test;
  `uvm_component_utils(uart_corner_test)

  uart_env env;
  uart_corner_sequence corner_seq;

  function new(string name = "uart_corner_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = uart_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    phase.phase_done.set_drain_time(this, 100_000);

    `uvm_info("CORNER_TEST", "Starting Corner-Case Vectors Test...", UVM_LOW)
    corner_seq = uart_corner_sequence::type_id::create("corner_seq");
    corner_seq.start(env.agent.sequencer);

    phase.drop_objection(this);
  endtask

endclass