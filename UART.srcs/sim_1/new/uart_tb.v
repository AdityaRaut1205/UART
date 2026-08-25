`timescale 1ns / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

// Include UVM Class Hierarchy in dependency order
`include "uart_transaction.v"
`include "uart_sequence.v"
`include "uart_sequencer.v"
`include "uart_driver.v"
`include "uart_monitor.v"
`include "uart_scoreboard.v"
`include "uart_agent.v"
`include "uart_env.v"
`include "uart_test.v"

module uart_tb;

  parameter integer CLK_FREQ    = 50_000_000;
  parameter integer BAUD_RATE   = 115200;
  parameter integer OVERSAMPLE  = 16;
  parameter integer DATA_BITS   = 8;
  parameter integer PARITY_MODE = 0;
  parameter integer STOP_BITS   = 1;

  logic clk;
  logic rst;

  // Instantiate SystemVerilog Interface
  uart_interface vif(clk, rst);

  // Instantiate Design Under Test (DUT Top)
  top #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE),
    .OVERSAMPLE(OVERSAMPLE),
    .DATA_BITS(DATA_BITS),
    .PARITY_MODE(PARITY_MODE),
    .STOP_BITS(STOP_BITS)
  ) dut (
    .clk(clk),
    .rst(rst),
    .tx_valid(vif.tx_valid),
    .tx_data(vif.tx_data),
    .rx_data(vif.rx_data),
    .rx_valid(vif.rx_valid),
    .parity_error(vif.parity_error),
    .framing_error(vif.framing_error),
    .tx_busy(vif.tx_busy)
  );

  // 50 MHz Clock Generator (Period = 20ns)
  initial begin
    clk = 0;
    forever #10 clk = ~clk;
  end

  // Active-High Reset Sequence
  initial begin
    rst = 1'b1;
    #100;
    @(posedge clk);
    rst = 1'b0;
  end

  // UVM Test Execution and Interface Registration
  initial begin
    uvm_config_db#(virtual uart_interface)::set(null, "*", "vif", vif);
    run_test("uart_test");
  end

  // Waveform dump for debug
  initial begin
    $dumpfile("uart_sim.vcd");
    $dumpvars(0, uart_tb);
  end

endmodule