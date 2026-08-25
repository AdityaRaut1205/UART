`timescale 1ns / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_transaction extends uvm_sequence_item;

  // Stimulus fields
  rand bit [7:0] tx_data;
  rand int unsigned delay; // Optional delay before sending (inter-packet delay)

  // Response / Status fields from DUT
  bit [7:0] rx_data;
  bit       parity_error;
  bit       framing_error;
  bit       tx_busy;
  bit       rx_valid;
  bit       tx_valid;

  // Constraints
  constraint c_delay { delay inside {[0:10]}; }

  function new(string name = "uart_transaction");
    super.new(name);
  endfunction

  `uvm_object_utils_begin(uart_transaction)
    `uvm_field_int(tx_data,       UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(rx_data,       UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(parity_error,  UVM_ALL_ON)
    `uvm_field_int(framing_error, UVM_ALL_ON)
    `uvm_field_int(tx_busy,       UVM_ALL_ON)
    `uvm_field_int(rx_valid,      UVM_ALL_ON)
    `uvm_field_int(tx_valid,      UVM_ALL_ON)
    `uvm_field_int(delay,         UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  virtual function string convert2string();
    return $sformatf("tx_data=0x%02h, rx_data=0x%02h, parity_err=%0b, framing_err=%0b", 
                     tx_data, rx_data, parity_error, framing_error);
  endfunction

endclass