# Design & UVM Verification of UART Controller

A synthesizable full-duplex Universal Asynchronous Receiver-Transmitter (UART) core designed in SystemVerilog/Verilog and verified using a layered UVM 1.2 testbench in AMD Vivado.

---

## 📌 Features & Specifications

- **Protocol:** Standard 8-N-1 (1 Start bit, 8 Data bits, No Parity, 1 Stop bit)
- **System Clock:** 50 MHz (T = 20 ns)
- **Baud Rate:** 115,200 bps (T_bit ≈ 8.68 µs)
- **Oversampling:** 16x oversampling on the RX line with 8th-tick midpoint start-bit detection
- **Clock Synchronization:** Phase-locked baud generator (TX enable derived directly from 16 RX enable ticks to eliminate cumulative clock drift)
- **Verification Methodology:** UVM 1.2 layered testbench with constrained random stimulus, 8 critical corner cases, and concurrent SystemVerilog Assertions (SVA)
- **Scoreboard:** FIFO queue-based self-checking comparator (`expected_tx_q[$]`) with end-of-test queue drain checks
- **Simulation Result:** 28/28 packets verified with 0 mismatches, 0 framing/parity errors, and 0 UVM errors

---

## 🏗️ Architecture

### RTL Top Module
```
                        +----------------------+
                        | baud_rate_generator  |
                        +----------+-----------+
                                   |
                  +----------------+----------------+
                  | tx_enb (1x)                     | rx_enb (16x)
                  v                                 v
tx_valid  ──► +--------+     tx_serial (Loopback)  +--------+ ──► rx_data[7:0]
tx_data   ──► | uart_tx| ------------------------> | uart_rx| ──► rx_valid
tx_busy   ◄── +--------+                           +--------+ ──► parity/framing errors
```

### UVM Testbench Hierarchy
```
+-----------------------------------------------------------------------+
|                               uart_test                               |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  |                            uart_env                             |  |
|  |                                                                 |  |
|  |  +---------------------------+       +-----------------------+  |  |
|  |  |        uart_agent         |       |    uart_scoreboard    |  |  |
|  |  |                           |       |                       |  |  |
|  |  |  +---------------------+  |       | +-------------------+ |  |  |
|  |  |  |    uart_sequence    |  |       | |  expected_tx_q[$] | |  |  |
|  |  |  +----------+----------+  |       | +---------+---------+ |  |  |
|  |  |             |             |       |           |           |  |  |
|  |  |             v             |       |           v           |  |  |
|  |  |  +---------------------+  |       |      write_tx()       |  |  |
|  |  |  |   uart_sequencer    |  |       |      write_rx()       |  |  |
|  |  |  +----------+----------+  |       |   (Expected vs RX)    |  |  |
|  |  |             |             |       +-----------^-----------+  |  |
|  |  |             v             |                   |              |  |
|  |  |  +---------------------+  |     tx_port       |              |  |
|  |  |  |     uart_driver     +--+-------------------+              |  |
|  |  |  +----------+----------+  |     rx_port       |              |  |
|  |  |             |             |                   |              |  |
|  |  |             v             |                   |              |  |
|  |  |  +---------------------+  |                   |              |  |
|  |  |  |    uart_monitor     +--+-------------------+              |  |
|  |  |  +---------------------+  |                                  |  |
|  |  +-------------+-------------+                                  |  |
|  +----------------|------------------------------------------------+  |
+-------------------|---------------------------------------------------+
                    |
                    v (via virtual interface vif)
           +-----------------+
           |     DUT Top     |
           +-----------------+
```

---

## 📁 Repository Structure

```
UART/
├── UART.srcs/
│   ├── sources_1/new/             # Synthesizable RTL Design Sources
│   │   ├── top.v                  # Hardware top-level wrapper (loopback)
│   │   ├── baud_rate_generator.v  # Phase-locked clock divider (50MHz -> 115.2k / 16x)
│   │   ├── uart_tx.v              # 5-State transmitter FSM
│   │   └── uart_rx.v              # 16x oversampling receiver FSM
│   │
│   └── sim_1/new/                 # UVM Verification Testbench Files
│       ├── uart_interface.v       # SV Interface with modports & Assertions (SVA)
│       ├── uart_transaction.v     # Sequence item data packet
│       ├── uart_sequence.v        # Corner-case & random sequences
│       ├── uart_sequencer.v       # Sequence-Driver arbitration bridge
│       ├── uart_driver.v          # Transaction-to-pin driver with reset sync
│       ├── uart_monitor.v         # Passive sniffer with dual analysis ports
│       ├── uart_scoreboard.v      # In-order queue comparator & report summary
│       ├── uart_agent.v           # Reusable UVM Agent
│       ├── uart_env.v             # UVM Environment
│       ├── uart_test.v            # UVM Test with 100us objection drain time
│       └── uart_tb.v              # Testbench top (50MHz clock & reset generator)
│
├── UART.xpr                       # Vivado Project File
└── README.md
```

---

## 🧪 Verification Strategy

### 1. Stimulus Generation (`uart_sequence.v`)
- **Corner Cases (8 Vectors):**
  - `0x00` (All zeros — verifies 0 data is not confused with start bit)
  - `0xFF` (All ones — verifies 1 data is not confused with idle/stop bit)
  - `0xAA` & `0x55` (Alternating bit patterns — maximum toggling rate)
  - `0xA5` & `0x5A` (Asymmetric nibble patterns)
  - `0x01` & `0x80` (Walking boundary bits — verifies LSB/MSB shift ordering)
- **Constrained Random:** 20 randomized data packets with variable inter-packet delays (0 to 10 clock cycles).

### 2. SystemVerilog Assertions (`uart_interface.v`)
- **Reset Check:** Confirms `tx_busy == 0` and `rx_valid == 0` during active reset.
- **Data Integrity:** Ensures `rx_data` contains no `X` or `Z` bits when `rx_valid` pulses.

### 3. Scoreboard Verification (`uart_scoreboard.v`)
- Stores expected bytes in an internal FIFO queue (`expected_tx_q[$]`) upon transmission.
- Pops and verifies bytes upon `rx_valid` assertion.
- Confirms the queue is completely drained (`expected_tx_q.size() == 0`) at end-of-test.

---

## 📊 Simulation Results

Simulation completed in Vivado XSim with **100% match**:

```text
--------------------------------------------------------
               UART VERIFICATION REPORT                 
--------------------------------------------------------
 Total Packets Transmitted : 28
 Total Packets Received    : 28
 Passed Matches            : 28
 Failed Mismatches         : 0
 Parity Errors             : 0
 Framing Errors            : 0
--------------------------------------------------------
  *** TEST PASSED ALL COMPARISONS SUCCESSFULLY ***   
--------------------------------------------------------

--- UVM Report Summary ---
** Report counts by severity
UVM_INFO    : 50
UVM_WARNING : 0
UVM_ERROR   : 0
UVM_FATAL   : 0
```

---

## 🚀 How to Run Simulation

### In Vivado GUI:
1. Open the Vivado project `UART.xpr`.
2. Click **Run Simulation -> Run Behavioral Simulation**.
3. In the Tcl Console, run:
   ```tcl
   run -all
   ```
