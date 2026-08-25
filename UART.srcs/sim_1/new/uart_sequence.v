`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: uart_sequence
// Description: UVM Sequences for UART stimulus generation including:
//              - uart_random_sequence: Random payloads with varying delays
//              - uart_corner_sequence: Boundary values (0x00, 0xFF, 0x55, 0xAA)
//              - uart_sequence: Combined regression sequence
//////////////////////////////////////////////////////////////////////////////////

import uvm_pkg::*;
`include "uvm_macros.svh"

// ---------------------------------------------------------
// Random Stimulus Sequence
// ---------------------------------------------------------
class uart_random_sequence extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_random_sequence)

    int unsigned num_transactions = 20;

    function new(string name = "uart_random_sequence");
        super.new(name);
    endfunction

    task body();
        uart_transaction tr;
        `uvm_info("SEQ_RAND", $sformatf("Starting Random Sequence (%0d transactions)...", num_transactions), UVM_LOW)

        repeat (num_transactions) begin
            tr = uart_transaction::type_id::create("tr");
            start_item(tr);
            if (!tr.randomize()) begin
                `uvm_error("SEQ_RAND", "Randomization failed!")
            end
            finish_item(tr);
        end
    endtask
endclass

// ---------------------------------------------------------
// Corner-Case Stimulus Sequence (Boundary & Walking bits)
// ---------------------------------------------------------
class uart_corner_sequence extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_corner_sequence)

    // Critical corner test vectors
    bit [7:0] corner_cases[$] = '{
        8'h00, // All zeros
        8'hFF, // All ones
        8'hAA, // Alternating 10101010
        8'h55, // Alternating 01010101
        8'hA5, // 10100101
        8'h5A, // 01011010
        8'h01, // LSB only
        8'h80  // MSB only
    };

    function new(string name = "uart_corner_sequence");
        super.new(name);
    endfunction

    task body();
        uart_transaction tr;
        `uvm_info("SEQ_CORNER", "Starting Corner-Case Sequence...", UVM_LOW)

        foreach (corner_cases[i]) begin
            tr = uart_transaction::type_id::create("tr");
            start_item(tr);
            if (!tr.randomize() with { tx_data == corner_cases[i]; delay == 1; }) begin
                `uvm_error("SEQ_CORNER", "Randomization failed!")
            end
            finish_item(tr);
        end
    endtask
endclass

// ---------------------------------------------------------
// Master Regression Sequence (Default)
// ---------------------------------------------------------
class uart_sequence extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_sequence)

    function new(string name = "uart_sequence");
        super.new(name);
    endfunction

    task body();
        uart_corner_sequence corner_seq;
        uart_random_sequence rand_seq;

        `uvm_info("SEQ_MAIN", "=== Starting Master UART Sequence ===", UVM_LOW)

        // 1. Run Corner Cases First
        corner_seq = uart_corner_sequence::type_id::create("corner_seq");
        corner_seq.start(m_sequencer, this);

        // 2. Run Random Sequence
        rand_seq = uart_random_sequence::type_id::create("rand_seq");
        rand_seq.num_transactions = 20;
        rand_seq.start(m_sequencer, this);

        `uvm_info("SEQ_MAIN", "=== Master UART Sequence Finished ===", UVM_LOW)
    endtask
endclass
