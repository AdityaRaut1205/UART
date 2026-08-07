# UART
# UART Transmitter and Receiver

This project implements a **parameterized UART (Universal Asynchronous Receiver/Transmitter)** in SystemVerilog.

### Functionality

The UART consists of:

* **Baud Rate Generator** – generates the timing enable signals for TX and 16× oversampled RX.
* **UART Transmitter** – converts parallel data into a serial UART frame containing a start bit, data bits, optional parity bit, and stop bit.
* **UART Receiver** – detects the start bit, samples the incoming serial data at the center of each bit, reconstructs the parallel data, and checks parity and framing errors.
* **Top Module** – integrates the transmitter, receiver, and baud-rate generator using a TX-to-RX loopback connection.

The design supports configurable:

* Baud rate
* Data width
* Parity mode
* Number of stop bits
* RX oversampling factor

The current design is verified using a SystemVerilog testbench with TX-to-RX loopback for multiple test patterns.
