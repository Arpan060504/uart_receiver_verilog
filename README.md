# UART Receiver in Verilog

An 8-bit UART receiver implemented in Verilog HDL using a finite state machine (FSM). The receiver detects and validates the start bit, samples serial data in LSB-first order, validates the stop bit, rejects invalid frames, and generates a one-clock-cycle `rx_done` pulse after successful reception.

## Features

- 8-bit serial data reception
- FSM-based control architecture
- Start-bit detection and validation
- False-start rejection
- LSB-first data reception
- Serial-to-parallel conversion
- Stop-bit validation
- Invalid-frame rejection
- One-clock-cycle `rx_done` pulse
- Preservation of the last valid `rx_data`
- Testbench verification with multiple frame conditions

## FSM Architecture

The receiver is implemented using four states:

| State | Function |
|---|---|
| `IDLE` | Waits for the RX line to transition LOW |
| `START` | Validates the detected start bit |
| `RECEIVE` | Samples and stores 8 serial data bits |
| `STOP` | Validates the stop bit and accepts or rejects the frame |

State flow:

```text
                 Valid start
     ┌──────┐  ──────────────>  ┌───────┐
     │ IDLE │                   │ START │
     └──────┘  <──────────────  └───────┘
        ▲        False start         │
        │                            │ Start validated
        │                            ▼
     ┌──────┐                  ┌─────────┐
     │ STOP │  <─────────────  │ RECEIVE │
     └──────┘    8 bits done   └─────────┘
        │
        └──────────────> IDLE
```

## UART Frame Format

The receiver expects a basic 8-bit UART frame:

```text
Idle   Start    8 Data Bits (LSB First)    Stop
  1      0      D0 D1 D2 D3 D4 D5 D6 D7     1
```

Example for `8'hA5`:

```text
A5 = 1010_0101

Parallel bit positions:
D7 D6 D5 D4 D3 D2 D1 D0
 1  0  1  0  0  1  0  1

UART wire order:
D0 D1 D2 D3 D4 D5 D6 D7
 1  0  1  0  0  1  0  1
```

## Module Interface

| Signal | Direction | Width | Description |
|---|---|---:|---|
| `clk` | Input | 1 bit | System clock |
| `reset` | Input | 1 bit | Active-high synchronous reset |
| `rx` | Input | 1 bit | Serial UART receive line |
| `rx_data` | Output | 8 bits | Last successfully received byte |
| `rx_done` | Output | 1 bit | Pulses HIGH for one clock cycle after a valid frame |

## Design Overview

### 1. Idle Detection

The UART line remains HIGH while idle. The receiver waits in the `IDLE` state until:

```verilog
rx == 0
```

A LOW level is treated as a possible start bit.

### 2. Start-Bit Validation

After detecting a LOW level, the FSM enters the `START` state. The receiver waits until the configured midpoint count before accepting the start bit.

If `rx` returns HIGH before validation, the event is treated as a false start and the FSM returns to `IDLE`.

### 3. Data Reception

After successful start-bit validation, the receiver enters the `RECEIVE` state.

Eight bits are sampled and stored directly into:

```verilog
shift_reg[bit_count]
```

Because UART transmits the least significant bit first, the first received bit is stored in bit position `0`, followed by bit positions `1` through `7`.

### 4. Stop-Bit Validation

After receiving all eight data bits, the FSM enters the `STOP` state.

The frame is accepted only when the stop bit is HIGH:

```verilog
rx == 1
```

For a valid frame:

```verilog
rx_data <= shift_reg;
rx_done <= 1;
```

For an invalid stop bit, the received frame is rejected. `rx_data` retains the previously received valid byte and `rx_done` remains LOW.

## Timing Parameters

The current design uses a simplified educational timing model:

```verilog
parameter BAUD_MAX = 2'b11;
parameter BAUD_MID = 2'b10;
```

The testbench models each UART bit with a duration of four system clock periods.

This implementation is intended to demonstrate UART receiver architecture, FSM control, counter-based timing, and verification. It is not intended to represent a production-ready baud-rate generator.

## Verification

The testbench verifies the receiver under multiple operating conditions.

### Test 1 — Valid `8'hA5` Frame

Input frame:

```text
START | 1 0 1 0 0 1 0 1 | STOP
  0   |   LSB first      |  1
```

Expected result:

```text
rx_data = 8'hA5
rx_done = 1 for one clock cycle
```

Observed result:

```text
rx_data = 8'hA5
rx_done pulses successfully
```

### Test 2 — False-Start Rejection

A short LOW pulse is applied to the RX line, but the line returns HIGH before start-bit validation completes.

Expected behavior:

```text
START detection begins
        ↓
RX returns HIGH early
        ↓
FSM returns to IDLE
        ↓
No rx_done pulse
```

The previously received valid data remains unchanged.

### Test 3 — Valid `8'h0F` Frame

UART wire order:

```text
D0 D1 D2 D3 D4 D5 D6 D7
 1  1  1  1  0  0  0  0
```

Expected result:

```text
rx_data = 8'h0F
rx_done = 1 for one clock cycle
```

Observed result:

```text
rx_data = 8'h0F
rx_done pulses successfully
```

### Test 4 — Invalid Stop-Bit Rejection

An `8'hFF` data sequence is transmitted with an invalid LOW stop bit.

Data reception:

```text
D0 D1 D2 D3 D4 D5 D6 D7
 1  1  1  1  1  1  1  1
```

Invalid frame ending:

```text
STOP = 0
```

Expected behavior:

```text
shift_reg = 8'hFF
rx_data   = previous valid value
rx_done   = 0
```

Observed behavior:

```text
shift_reg = 8'hFF
rx_data   = 8'h0F
rx_done   = 0
```

The invalid frame is correctly rejected, and the previous valid byte is preserved.

## Verification Summary

| Test Case | Expected Result | Status |
|---|---|---|
| Valid `8'hA5` frame | Receive `A5`, pulse `rx_done` | Pass |
| False start | Return to `IDLE`, no completion pulse | Pass |
| Valid `8'h0F` frame | Receive `0F`, pulse `rx_done` | Pass |
| Invalid stop bit | Reject frame, preserve previous data | Pass |

## Project Structure

```text
uart-receiver-verilog/
├── uart_rx.v
├── uart_rx_tb.v
├── README.md
└── .gitignore
```

## Simulation

### Requirements

- Icarus Verilog
- GTKWave

### Compile

```bash
iverilog -o uart_rx_test uart_rx.v uart_rx_tb.v
```

### Run

```bash
vvp uart_rx_test
```

### View Waveform

```bash
gtkwave uart_test.vcd
```

## Tools Used

- Verilog HDL
- Icarus Verilog
- GTKWave
- Visual Studio Code

## Key Learning Outcomes

This project demonstrates practical understanding of:

- Finite state machine design
- Sequential and combinational RTL separation
- UART frame structure
- Start-bit detection
- False-start rejection
- Counter-based sampling
- LSB-first serial reception
- Serial-to-parallel conversion
- Stop-bit validation
- One-cycle status pulse generation
- Nonblocking assignments in sequential logic
- Testbench development
- Waveform-based RTL debugging

## Current Limitations

This is an educational UART receiver implementation. Current limitations include:

- Fixed simplified baud timing
- No configurable baud-rate divider
- No two-flop synchronizer on the asynchronous RX input
- No 8x or 16x oversampling
- No majority-vote sampling
- No parity support
- No explicit framing-error output
- No FIFO buffering

## Future Improvements

Possible extensions include:

- Parameterized baud-rate generation
- RX input synchronizer
- 8x or 16x oversampling
- Majority-vote bit sampling
- Configurable data width
- Optional parity checking
- Framing-error output
- RX FIFO buffering
- Integration with a UART transmitter
- Full-duplex UART module

## Author

**Arpan**  
Electrical Engineering  
NIT Durgapur
