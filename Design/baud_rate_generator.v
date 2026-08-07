`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.08.2026 19:24:49
// Design Name: 
// Module Name: baud_rate_generator
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

    // Counter values
    localparam integer TX_DIV = CLK_FREQ / BAUD_RATE;
    localparam integer RX_DIV = CLK_FREQ / (BAUD_RATE * OVERSAMPLE);  //oversampling

    // Counter widths
    localparam integer TX_WIDTH = $clog2(TX_DIV);     //reg width for tx_count
    localparam integer RX_WIDTH = $clog2(RX_DIV);     //reg width for rx_count  

    reg [TX_WIDTH-1:0] tx_count;
    reg [RX_WIDTH-1:0] rx_count;


    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            tx_count <= 0;
            rx_count <= 0;

            tx_enb <= 1'b0;
            rx_enb <= 1'b0;
        end
        else
        begin
           
            // Default outputs
            tx_enb <= 1'b0;
            rx_enb <= 1'b0;

            //tx_enb is set 1 after every TX_DIV number of cycles
            if(tx_count == TX_DIV-1)
            begin
                tx_count <= 0;
                tx_enb   <= 1'b1;
            end
            else
            begin
                tx_count <= tx_count + 1'b1;
            end


            //rx_enb is set 1 after every RX_DIV number of cycles
            if(rx_count == RX_DIV-1)
            begin
                rx_count <= 0;
                rx_enb   <= 1'b1;
            end
            else
            begin
                rx_count <= rx_count + 1'b1;
            end
        end
    end

endmodule
