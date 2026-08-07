`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.08.2026 19:56:36
// Design Name: 
// Module Name: uart_tx
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

module uart_tx #(
    parameter integer DATA_BITS   = 8,
    parameter int PARITY_MODE = 0,    //0=None, 1=Even, 2=Odd
    parameter int STOP_BITS   = 1     //Stop bits can be 1 or 2
)(
    input logic clk,
    input logic rst,
    input logic tx_enb,                     //from baud rate generator module
    input logic tx_valid,
    input logic [DATA_BITS-1:0] tx_data,    //Parallel data
    output logic tx_serial,                 //to the rx module
    output logic tx_busy
);

// State Encoding
localparam [2:0]        //there are 5 states so 3 bits are needed
    IDLE   = 3'd0,      //000
    START  = 3'd1,      //001
    DATA   = 3'd2,      //010
    PARITY = 3'd3,      //011
    STOP   = 3'd4;      //100

logic [2:0] state, next_state;

logic [DATA_BITS-1:0] shift_reg;            
logic [$clog2(DATA_BITS)-1 :0] bit_cnt;  //used to count how many data bits have been transmitted.
logic parity_bit;
logic stop_cnt;      //either 1 or 2

//block only stores the current state.
always_ff @(posedge clk or posedge rst)   //flip-flop with asynchronous active-high reset.
    if(rst) state <= IDLE;                //immediate reset
    else    state <= next_state;


//This block only decides where to go next.
always_comb begin
    next_state = state;
    case(state)
      IDLE   : if(tx_valid)
                    next_state = START;
      START  : if(tx_enb)
                    next_state = DATA;
      DATA   : if(tx_enb && bit_cnt==DATA_BITS-1)
                    next_state = (PARITY_MODE==0) ? STOP : PARITY;
      PARITY : if(tx_enb) 
                    next_state = STOP;
      STOP   : if(tx_enb && stop_cnt==STOP_BITS-1)
                  next_state = tx_valid ? START : IDLE;
      default:
             next_state = IDLE;            
    endcase
end

//we can write the FSM using one always_ff block
//but for large designs it becomes harder to:
//debug FSM transitions, modify states, avoid accidental mistakes ,verify using UVM

//Here we used two-process FSM design style

//Updation is done in this block
always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        shift_reg<=0; 
        bit_cnt<=0; 
        stop_cnt<=0;
        tx_serial<=1'b1;
        tx_busy<=1'b0;
        parity_bit<=0;
    end
    else begin
        case(state)
          IDLE: begin
            tx_serial<=1'b1;
            bit_cnt<=0;
            stop_cnt<=0;
            if(tx_valid) begin
                shift_reg <= tx_data;
                //for even parity total number of 1s (data + parity bit) must be even.
                parity_bit <= (PARITY_MODE==1)? ^tx_data :        
                              (PARITY_MODE==2)? ~^tx_data : 1'b0;
                tx_busy<=1'b1;
            end
            else tx_busy <= 1'b0;
          end
          
          START: if(tx_enb) begin
              tx_serial<=1'b0;    //tx is pulled low to indicate start
              bit_cnt<=0;
          end
          
          DATA: if(tx_enb) begin
              tx_serial <= shift_reg[0];        //LSB first
              shift_reg <= {1'b0,shift_reg[DATA_BITS-1:1]};   //shifting
              bit_cnt <= bit_cnt+1;
          end
          
          PARITY: if(tx_enb)
              tx_serial <= parity_bit;
          
          STOP: if(tx_enb) begin
              tx_serial <= 1'b1;  //0 indiactes start transmission, 1 for stop.
              if(stop_cnt == STOP_BITS-1) begin
                  stop_cnt<=0;
                  if(tx_valid) begin                //Check if new data is waiting
                      bit_cnt <= 0;
                      shift_reg <= tx_data;      //Copy the new parallel data into the shift register.
                      parity_bit <= (PARITY_MODE==1)? ^tx_data :
                                    (PARITY_MODE==2)? ~^tx_data : 1'b0;
                      tx_busy <= 1'b1;
                  end
                  else tx_busy <= 1'b0;
              end
              else stop_cnt <= stop_cnt+1;
          end
        endcase
    end
end

endmodule