`timescale 1ns / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

`uvm_analysis_imp_decl(_tx)
`uvm_analysis_imp_decl(_rx)

class uart_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_scoreboard)

  uvm_analysis_imp_tx #(uart_transaction, uart_scoreboard) tx_export;
  uvm_analysis_imp_rx #(uart_transaction, uart_scoreboard) rx_export;

  // Expected transaction queue
  bit [7:0] expected_tx_q[$];

  // Statistics counters
  int num_tx_pkts   = 0;
  int num_rx_pkts   = 0;
  int num_passed    = 0;
  int num_failed    = 0;
  int parity_errors = 0;
  int framing_errors= 0;

  function new(string name = "uart_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    tx_export = new("tx_export", this);
    rx_export = new("rx_export", this);
  endfunction

  // Called whenever the monitor observes a TX transmission
  virtual function void write_tx(uart_transaction tx);
    expected_tx_q.push_back(tx.tx_data);
    num_tx_pkts++;
    `uvm_info("SCB_TX", $sformatf("Pushed to Expected Queue: 0x%02h (Queue size = %0d)", 
              tx.tx_data, expected_tx_q.size()), UVM_HIGH)
  endfunction

  // Called whenever the monitor observes an RX reception
  virtual function void write_rx(uart_transaction rx);
    bit [7:0] expected_val;
    num_rx_pkts++;

    if (rx.parity_error)  parity_errors++;
    if (rx.framing_error) framing_errors++;

    if (expected_tx_q.size() == 0) begin
      `uvm_error("SCB_UNEXPECTED", $sformatf("Received RX byte 0x%02h but expected queue is EMPTY!", rx.rx_data))
      num_failed++;
      return;
    end

    expected_val = expected_tx_q.pop_front();

    if (expected_val === rx.rx_data && !rx.parity_error && !rx.framing_error) begin
      `uvm_info("SCB_MATCH", $sformatf("[PASS] TX: 0x%02h == RX: 0x%02h (ParityErr=%0b, FramingErr=%0b)", 
                expected_val, rx.rx_data, rx.parity_error, rx.framing_error), UVM_LOW)
      num_passed++;
    end
    else begin
      `uvm_error("SCB_MISMATCH", $sformatf("[FAIL] Expected TX: 0x%02h != Actual RX: 0x%02h (ParityErr=%0b, FramingErr=%0b)", 
                 expected_val, rx.rx_data, rx.parity_error, rx.framing_error))
      num_failed++;
    end
  endfunction

  // Verification checks at the end of simulation
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (expected_tx_q.size() > 0) begin
      `uvm_error("SCB_QUEUE_NOT_EMPTY", $sformatf("Simulation ended with %0d unverified packets remaining in queue!", expected_tx_q.size()))
    end
  endfunction

  // Detailed test summary report
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD_SUMMARY", "--------------------------------------------------------", UVM_NONE)
    `uvm_info("SCOREBOARD_SUMMARY", "               UART VERIFICATION REPORT                 ", UVM_NONE)
    `uvm_info("SCOREBOARD_SUMMARY", "--------------------------------------------------------", UVM_NONE)
    `uvm_info("SCOREBOARD_SUMMARY", $sformatf(" Total Packets Transmitted : %0d", num_tx_pkts), UVM_NONE)
    `uvm_info("SCOREBOARD_SUMMARY", $sformatf(" Total Packets Received    : %0d", num_rx_pkts), UVM_NONE)
    `uvm_info("SCOREBOARD_SUMMARY", $sformatf(" Passed Matches            : %0d", num_passed), UVM_NONE)
    `uvm_info("SCOREBOARD_SUMMARY", $sformatf(" Failed Mismatches         : %0d", num_failed), UVM_NONE)
    `uvm_info("SCOREBOARD_SUMMARY", $sformatf(" Parity Errors             : %0d", parity_errors), UVM_NONE)
    `uvm_info("SCOREBOARD_SUMMARY", $sformatf(" Framing Errors            : %0d", framing_errors), UVM_NONE)
    `uvm_info("SCOREBOARD_SUMMARY", "--------------------------------------------------------", UVM_NONE)

    if (num_failed == 0 && expected_tx_q.size() == 0 && num_passed > 0) begin
      `uvm_info("SCOREBOARD_SUMMARY", "  *** TEST PASSED ALL COMPARISONS SUCCESSFULLY ***   ", UVM_NONE)
    end
    else begin
      `uvm_error("SCOREBOARD_SUMMARY", "  *** TEST FAILED - CHECK LOG FOR ERRORS ***         ")
    end
    `uvm_info("SCOREBOARD_SUMMARY", "--------------------------------------------------------", UVM_NONE)
  endfunction

endclass