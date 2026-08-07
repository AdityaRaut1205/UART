`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.08.2026 22:33:44
// Design Name: 
// Module Name: uart_tb
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

module uart_tb;

parameter integer CLK_FREQ    = 50_000_000;
parameter integer BAUD_RATE   = 115200;
parameter integer OVERSAMPLE  = 16;
parameter integer DATA_BITS   = 8;
parameter integer PARITY_MODE = 0;
parameter integer STOP_BITS   = 1;

logic clk;
logic rst;
logic tx_valid;
logic [DATA_BITS-1:0] tx_data;

logic [DATA_BITS-1:0] rx_data;
logic rx_valid;
logic parity_error;
logic framing_error;
logic tx_busy;


// DUT
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
    .tx_valid(tx_valid),
    .tx_data(tx_data),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .parity_error(parity_error),
    .framing_error(framing_error),
    .tx_busy(tx_busy)
);

// Clock Generation (20 ns period)
initial
    clk = 0;
always #10 clk = ~clk;


// Reset Generation
initial begin
    rst      = 1'b1;
    tx_valid = 1'b0;
    tx_data  = '0;

    #100;
    rst = 1'b0;
end


// Task to transmit one byte
task send_data(input [DATA_BITS-1:0] data);
  begin
    tx_data  = data;
    tx_valid = 1'b1;
    wait(tx_busy);
    @(posedge clk);
    tx_valid = 1'b0;
    //Once the transmitter has loaded the data
    //the request is finished, so we deassert (0).

    wait(rx_valid);
    if(rx_data == data)
        $display("[%0t] PASS : Sent = %h  Received = %h",$time,data,rx_data);
    else
        $display("[%0t] FAIL : Sent = %h  Received = %h",$time,data,rx_data);

    wait(tx_busy == 0);
    //make sure the previous transmission is completed before sending new data.

end
endtask


// Test Sequence
initial begin
    @(negedge rst);    //when rst==0
    //sending 5 test cases
    send_data(8'hA5);
    send_data(8'h55);
    send_data(8'hFF);
    send_data(8'h00);
    send_data(8'h3C);

    #100;

    $display("--------------------------------");
    $display("Simulation Completed Successfully");
    $display("--------------------------------");

    $finish;

end

endmodule
