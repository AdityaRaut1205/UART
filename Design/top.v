`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.08.2026 20:24:45
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top #(
    parameter integer CLK_FREQ   = 50_000_000,   //50 MHz
    parameter integer BAUD_RATE  = 115200,
    parameter integer OVERSAMPLE = 16,
    parameter integer DATA_BITS  = 8,
    parameter integer PARITY_MODE = 0,
    parameter integer STOP_BITS   = 1
)(
    input logic clk,
    input logic rst,
    input logic tx_valid,
    input logic [DATA_BITS-1:0] tx_data,

    output logic [DATA_BITS-1:0] rx_data,
    output logic rx_valid,
    output logic parity_error,
    output logic framing_error,
    output logic tx_busy
);
    // for Internal Signals connections
    logic tx_enb;
    logic rx_enb;
    logic tx_serial;

    // Baud Rate Generator
    baud_rate_generator #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE),
        .OVERSAMPLE (OVERSAMPLE)
    ) baud_gen_inst (
        .clk (clk),
        .rst (rst),
        .tx_enb (tx_enb),
        .rx_enb (rx_enb)
    );

    // UART Transmitter
    uart_tx #(
        .DATA_BITS (DATA_BITS),
        .PARITY_MODE (PARITY_MODE),
        .STOP_BITS (STOP_BITS)
    ) tx_inst (
        .clk (clk),
        .rst (rst),
        .tx_enb (tx_enb),
        .tx_valid (tx_valid),
        .tx_data (tx_data),
        .tx_serial (tx_serial),
        .tx_busy (tx_busy)
    );

    // UART Receiver
    uart_rx #(
        .DATA_BITS (DATA_BITS),
        .PARITY_MODE (PARITY_MODE),
        .STOP_BITS (STOP_BITS),
        .CLKS_PER_BIT (OVERSAMPLE)
    ) rx_inst (
        .clk (clk),
        .rst (rst),
        .rx_enb (rx_enb),
        .rx_serial (tx_serial),
        .rx_data (rx_data),
        .rx_valid (rx_valid),
        .parity_error (parity_error),
        .framing_error (framing_error)
    );

endmodule
