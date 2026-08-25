`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: baud_rate_generator
// Description: Generates synchronous tx_enb and rx_enb enable pulses for UART.
//              tx_enb is derived directly from 16x rx_enb oversample ticks to 
//              guarantee zero cumulative drift between TX and RX.
//////////////////////////////////////////////////////////////////////////////////

module baud_rate_generator #(
    parameter integer CLK_FREQ    = 50_000_000,
    parameter integer BAUD_RATE   = 115200,
    parameter integer OVERSAMPLE  = 16
)(
    input  wire clk,
    input  wire rst,

    output reg  tx_enb,
    output reg  rx_enb
);

    // RX oversampling divisor: system clocks per oversample tick
    localparam integer RX_DIV = CLK_FREQ / (BAUD_RATE * OVERSAMPLE);
    localparam integer RX_WIDTH = (RX_DIV > 1) ? $clog2(RX_DIV) : 1;
    localparam integer OS_WIDTH = (OVERSAMPLE > 1) ? $clog2(OVERSAMPLE) : 1;

    reg [RX_WIDTH-1:0] rx_count;
    reg [OS_WIDTH-1:0] os_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_count <= 0;
            os_count <= 0;
            tx_enb   <= 1'b0;
            rx_enb   <= 1'b0;
        end
        else begin
            // Default outputs
            tx_enb <= 1'b0;
            rx_enb <= 1'b0;

            if (rx_count == RX_DIV - 1) begin
                rx_count <= 0;
                rx_enb   <= 1'b1;

                // Derive tx_enb from oversampling ticks to eliminate baud drift
                if (os_count == OVERSAMPLE - 1) begin
                    os_count <= 0;
                    tx_enb   <= 1'b1;
                end
                else begin
                    os_count <= os_count + 1'b1;
                end
            end
            else begin
                rx_count <= rx_count + 1'b1;
            end
        end
    end

endmodule
