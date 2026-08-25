`timescale 1ns / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_driver extends uvm_driver #(uart_transaction);
  `uvm_component_utils(uart_driver)

  virtual uart_interface vif;

  function new(string name = "uart_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_interface)::get(this, "", "vif", vif))
      `uvm_fatal("DRIVER", "Unable to get interface vif from config_db")
  endfunction

  task run_phase(uvm_phase phase);
    uart_transaction tx;

    // Initialize interface pins
    vif.tx_valid <= 1'b0;
    vif.tx_data  <= 8'h00;

    // 1. Wait for reset to be deasserted (Fixes Bug: simulation hang at time 0)
    wait (vif.rst == 1'b0);
    @(posedge vif.clk);
    `uvm_info("DRIVER", "Reset deasserted, starting driver activity...", UVM_LOW)

    forever begin
      seq_item_port.get_next_item(tx);

      // Apply optional inter-packet delay
      if (tx.delay > 0) begin
        repeat (tx.delay) @(posedge vif.clk);
      end

      // Wait if transmitter is currently busy
      while (vif.tx_busy) begin
        @(posedge vif.clk);
      end

      // Drive transaction onto interface
      @(posedge vif.clk);
      vif.tx_data  <= tx.tx_data;
      vif.tx_valid <= 1'b1;
      `uvm_info("DRIVER", $sformatf("Driving TX Data = 0x%02h", tx.tx_data), UVM_HIGH)

      @(posedge vif.clk);
      vif.tx_valid <= 1'b0;

      // Wait for transmission to start and complete
      wait (vif.tx_busy == 1'b1);
      wait (vif.tx_busy == 1'b0);

      // Brief settling time
      @(posedge vif.clk);

      seq_item_port.item_done();
    end
  endtask

endclass