`timescale 1ns / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_monitor extends uvm_monitor;
  `uvm_component_utils(uart_monitor)

  virtual uart_interface vif;
  uvm_analysis_port #(uart_transaction) tx_port;
  uvm_analysis_port #(uart_transaction) rx_port;

  function new(string name = "uart_monitor", uvm_component parent = null);
    super.new(name, parent);
    tx_port = new("tx_port", this);
    rx_port = new("rx_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_interface)::get(this, "", "vif", vif))
      `uvm_fatal("MONITOR", "Unable to get interface vif from config_db")
  endfunction

  task run_phase(uvm_phase phase);
    // Wait for reset deassertion
    wait (vif.rst == 1'b0);
    @(posedge vif.clk);

    fork
      monitor_tx();
      monitor_rx();
    join
  endtask

  // Thread 1: Monitor TX transactions
  task monitor_tx();
    uart_transaction tx_item;
    forever begin
      @(posedge vif.clk);
      if (vif.tx_valid) begin
        tx_item = uart_transaction::type_id::create("tx_item");
        tx_item.tx_data  = vif.tx_data;
        tx_item.tx_valid = 1'b1;
        `uvm_info("MONITOR_TX", $sformatf("Captured TX transaction: 0x%02h", tx_item.tx_data), UVM_HIGH)
        tx_port.write(tx_item);
      end
    end
  endtask

  // Thread 2: Monitor RX transactions
  task monitor_rx();
    uart_transaction rx_item;
    forever begin
      @(posedge vif.clk);
      if (vif.rx_valid) begin
        rx_item = uart_transaction::type_id::create("rx_item");
        rx_item.rx_data       = vif.rx_data;
        rx_item.parity_error  = vif.parity_error;
        rx_item.framing_error = vif.framing_error;
        rx_item.rx_valid      = 1'b1;
        `uvm_info("MONITOR_RX", $sformatf("Captured RX transaction: 0x%02h (parity_err=%0b, framing_err=%0b)", 
                  rx_item.rx_data, rx_item.parity_error, rx_item.framing_error), UVM_HIGH)
        rx_port.write(rx_item);
      end
    end
  endtask

endclass