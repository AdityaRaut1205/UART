`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.08.2026 22:02:53
// Design Name: 
// Module Name: uart_rx
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

module uart_rx #(
    parameter int DATA_BITS   = 8,
    parameter int PARITY_MODE = 0, //0=None,1=Even,2=Odd
    parameter int STOP_BITS   = 1,
    parameter int CLKS_PER_BIT = 16  
    //rx_enb will become high for 16 times for every 1 time tx_enb become high
)(
    input  logic clk,
    input  logic rst,
    input  logic rx_enb,
    input  logic rx_serial,
    output logic [DATA_BITS-1:0] rx_data,
    output logic rx_valid,
    output logic parity_error,
    output logic framing_error
);

typedef enum logic[2:0] {IDLE,START,DATA,PARITY,STOP} state_t;
state_t state;
//IDLE=000, START=001, DATA=010, PARITY=011, STOP=100.

logic [DATA_BITS-1:0] shift_reg;
logic parity_bit;
int bit_cnt, stop_cnt;
int clk_cnt;   //counts clk cycles withinone bit period

localparam int HALF_BIT = (CLKS_PER_BIT/2)-1;
//we want sampling at middle i.e. when rx_enb become high for 8th time

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
        bit_cnt <= 0;
        stop_cnt <= 0;
        clk_cnt <= 0;
        rx_valid <= 0;
        parity_error <= 0;
        framing_error <= 0;
        rx_data <= '0;
    end
    else begin
        rx_valid <= 0;
          if(rx_enb) begin
            case(state)
            IDLE: begin
                parity_error <= 0;
                framing_error <= 0;
                clk_cnt <= 0;
                if(!rx_serial) state <= START;
                //transmission ine pulled low for starting transmission
            end
            START: begin
              //sampling at middle of bit
              if(clk_cnt == HALF_BIT-1) begin  
                if(!rx_serial) begin  //confirmed low at mid bit
                    bit_cnt <= 0;
                    clk_cnt <= 0;
                    state <= DATA;
                end
                else state <= IDLE;
              end 
              else clk_cnt <= clk_cnt + 1; 
            end
            
            DATA: begin
                // Start bit is verified at its middle (8th oversampling tick).
                // From the middle of the START bit to the middle of the first DATA bit
                // is one complete bit period (16 oversampling ticks), so wait CLKS_PER_BIT.
               if (clk_cnt == CLKS_PER_BIT-1) begin
                    clk_cnt <= 0;
                    shift_reg[bit_cnt] <= rx_serial;   // LSB received first (standard UART)
                    if (bit_cnt == DATA_BITS-1) begin
                        bit_cnt <= 0;
                        state   <= (PARITY_MODE == 0) ? STOP : PARITY;
                    end
                    else bit_cnt <= bit_cnt + 1;
               end
               else clk_cnt <= clk_cnt + 1;   
            end
            
            PARITY: begin
                //parity bit is sent after data bits
                // Data bits are already sampled at their midpoints.
                // Wait one full bit period (16 oversampling ticks) to reach the
                // midpoint of the parity bit and sample it accurately.
              if(clk_cnt == CLKS_PER_BIT-1) begin 
                clk_cnt <= 0; 
                parity_bit <= rx_serial;
                if(PARITY_MODE==1 && (rx_serial != ^shift_reg)) parity_error <= 1;
                else if(PARITY_MODE==2 && (rx_serial != ~^shift_reg)) parity_error<=1;
                state <= STOP;
              end
              else clk_cnt <= clk_cnt + 1;  
            end
            STOP: begin
                //stop bit should be 1 ,otherwise framing error
              if(clk_cnt == CLKS_PER_BIT-1) begin  
                clk_cnt <= 0;
                if(!rx_serial) framing_error <= 1;
                if(stop_cnt == STOP_BITS-1) begin
                    stop_cnt <= 0;
                    rx_data <= shift_reg;
                    rx_valid <= 1;
                    state <= IDLE;
                end
                else stop_cnt <= stop_cnt+1;
              end
              else clk_cnt <= clk_cnt + 1;  
            end
            
            default: state <= IDLE; 
            
            endcase
        end
    end
end
endmodule

