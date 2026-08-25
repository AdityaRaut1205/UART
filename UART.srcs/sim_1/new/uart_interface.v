`timescale 1ns / 1ps

interface uart_interface(input logic clk, input logic rst);

  logic       tx_valid;
  logic [7:0] tx_data;

  logic [7:0] rx_data;
  logic       rx_valid;
  logic       parity_error;
  logic       framing_error;
  logic       tx_busy;

  // Modports
  modport DRV (input clk, rst, tx_busy, output tx_valid, tx_data);
  modport MON (input clk, rst, tx_valid, tx_data, rx_data, rx_valid, parity_error, framing_error, tx_busy);

  // -------------------------------------------------------
  // SystemVerilog Assertions (SVA) for Protocol Verification
  // -------------------------------------------------------
  // 1. Check that during active reset, tx_busy and rx_valid are 0
  property p_reset_state;
    @(posedge clk) rst |-> (!tx_busy && !rx_valid);
  endproperty
  a_reset_state: assert property(p_reset_state)
    else $error("[SVA] Assertion failed: tx_busy or rx_valid asserted during reset!");

  // 2. Check that rx_data contains no X or Z when rx_valid is high
  property p_rx_valid_known;
    @(posedge clk) disable iff (rst) rx_valid |-> !$isunknown(rx_data);
  endproperty
  a_rx_valid_known: assert property(p_rx_valid_known)
    else $error("[SVA] Assertion failed: rx_data contains unknown bits (X/Z) when rx_valid is high!");

endinterface