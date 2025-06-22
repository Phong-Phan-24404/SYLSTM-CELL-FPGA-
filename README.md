# LSTM Cell - Verilog RTL Implementation (Q8.24 Fixed-Point)

This repository contains a synthesizable Verilog RTL implementation of a single LSTM (Long Short-Term Memory) cell, extracted from the TSMAE model for FPGA synthesis. The design eliminates DPI-C dependencies, uses lookup tables (LUTs) for activation functions, and is optimized for fixed-point arithmetic in Q8.24 format. It is suitable for synthesis on Xilinx FPGAs using Vivado.

## Project Overview
This project provides a hardware implementation of an LSTM cell, designed for FPGA synthesis. Key features include:
- **Fixed-Point Arithmetic**: Uses Q8.24 format (32-bit, 24 fractional bits) for efficient FPGA implementation.
- **Modular Design**: Separates gate computations, activation functions, and state updates into distinct submodules.
- **LUT-Based Activations**: Sigmoid and tanh functions implemented using precomputed lookup tables (LUTs).
- **Handshake Interface**: Controlled via `start` and `done` signals, with clock (`clk`) and reset (`rst`) inputs.
- **Memory Initialization**: Weights and biases loaded from `.mem` files using `$readmemh` (simulation and synthesis compatible).
- **Testbench**: Includes testbenches for simulation of the LSTM cell and activation functions.
- **Synthesis Flow**: Automated using a Vivado-generated Tcl script.

The design was developed as a standalone module from the TSMAE model, which originally used DPI-C and was not synthesizable.

## Repository Structure
The repository includes the full Vivado project directory. Key files and directories are:

- **/synthesis_lstm.srcs/**
  - **sources_1/**: RTL and SystemVerilog source files
    - `decoder_LSTM_cell.sv`: Top module and submodules (`compute_gates`, `gate_computation`, `calculate_ct`, `mat_vec_mul`, `multiplier`, `sigmoid`, `tanh`).
    - `sigmoid_LUT.vh`, `tanh_LUT.vh`: LUT files for sigmoid and tanh activation functions.
    - `W_ih_dec.mem`, `W_hh_dec.mem`, `b_ih_dec.mem`, `b_hh_dec.mem`: Memory files for weights and biases (generated from TSMAE Python scripts).
  - **sim_1/**: Testbench files
    - `tb_LSTM_cell.sv`: Testbench for the full LSTM cell.
    - `tb_sigmoidtanh.sv`: Testbench for sigmoid and tanh modules.
- **synthesis_lstm.tcl**: Vivado-generated Tcl script for synthesis and implementation.
- **Untitled0.ipynb**: Jupyter notebook for generating sigmoid and tanh LUTs.
- **simulation.png**: Waveform screenshot from simulation.
- **synth/LSTM_cell.xdc**: Timing and I/O constraints.
- **doc/**: Documentation images
  - `block_diagram.png`: High-level architecture.
  - `fsm_diagram.png`: Finite state machine (FSM) flow.
  - `timing_waveform.png`: Timing and handshake signals visualization.

## Module Description
### Top Module: `decoder_LSTM_cell`
The top module implements a single LSTM cell computation, processing input `x_t`, previous hidden state `h_prev`, and previous cell state `c_prev` to produce new states `h_t` and `c_t`.

**Parameters**:
- `DATA_WIDTH`: 32 (fixed, for Q8.24 format).
- `FRACTION_BITS`: 24 (fractional bits in Q8.24).
- `INPUT_SIZE`: 10 (default, configurable).
- `HIDDEN_SIZE`: 10 (default, configurable).

**Ports**:
- Inputs: `clk`, `rst`, `start`, `x_t[INPUT_SIZE]`, `h_prev[HIDDEN_SIZE]`, `c_prev[HIDDEN_SIZE]`.
- Outputs: `done`, `h_t[HIDDEN_SIZE]`, `c_t[HIDDEN_SIZE]`.

**Main Submodules**:
- `compute_gates`: Computes matrix-vector products (`W_ih * x_t + W_hh * h_prev + b_ih + b_hh`) for input, forget, cell, and output gates.
- `gate_computation`: Applies sigmoid and tanh activations and computes cell state (`c_t`) and hidden state (`h_t`).
- `calculate_ct`: Performs cell state update (`c_t = f * c_prev + i * g`).
- `mat_vec_mul`: Matrix-vector multiplication for gate computations.
- `multiplier`: Fixed-point multiplier for Q8.24 arithmetic.
- `sigmoid`, `tanh`: LUT-based activation functions (513 entries each).

## Simulation
The project includes two testbenches for verification:
- `tb_LSTM_cell.sv`: Tests the full `decoder_LSTM_cell` module.
- `tb_sigmoidtanh.sv`: Tests the `sigmoid` and `tanh` modules independently.

### How to Run
1. Open the Vivado project (`synthesis_lstm.xpr`) in Vivado.
2. Add all source files, testbenches, and LUT files to the project.
3. Set `tb_LSTM_cell` or `tb_sigmoidtanh` as the top module for simulation.
4. Configure the include path for `.vh` files: Project Settings > Verilog Options > Include Directories > Add `synthesis_lstm.srcs/sources_1/new`.
5. Run Behavioral Simulation in Vivado (Flow Navigator > Simulation > Run Behavioral Simulation).
6. View waveforms in the Vivado waveform viewer. A sample waveform is provided in `simulation.png`.

## Synthesis
The design has been synthesized using Vivado 2024.2 on a Xilinx `xck26-sfvc784-2LV-c` FPGA.

### How to Run
1. Open `synthesis_lstm.xpr` in Vivado.
2. Run the synthesis.

## Synthesis Results
Synthesis was performed using Vivado 2024.2 on June 22, 2025. Key utilization metrics for the `decoder_LSTM_cell` design:

### CLB Logic
| Site Type            | Used | Available | Util% |
|----------------------|------|-----------|-------|
| CLB LUTs             | 308  | 117,120   | 0.26  |
| LUT as Logic         | 308  | 117,120   | 0.26  |
| CLB Registers        | 471  | 234,240   | 0.20  |
| Register as Flip Flop| 471  | 234,240   | 0.20  |
| CARRY8               | 20   | 14,640    | 0.14  |

### Block RAM
| Site Type      | Used | Available | Util% |
|----------------|------|-----------|-------|
| Block RAM Tile | 0    | 144       | 0.00  |
| RAMB36/FIFO    | 0    | 144       | 0.00  |
| RAMB18         | 0    | 288       | 0.00  |

### I/O
| Site Type  | Used | Available | Util%  |
|------------|------|-----------|--------|
| Bonded IOB | 644  | 189       | 340.74 |

*Note*: The high IOB utilization (340.74%) indicates an issue with the design’s I/O requirements exceeding the target device’s capacity. This may require I/O optimization or a larger FPGA.

### Primitives
| Primitive | Count |
|-----------|-------|
| OBUF      | 641   |
| FDCE      | 396   |
| LUT3      | 191   |
| LUT4      | 106   |
| FDPE      | 66    |
| LUT2      | 46    |
| LUT6      | 40    |
| LUT5      | 21    |
| CARRY8    | 20    |
| FDRE      | 9     |
| INBUF     | 3     |
| IBUFCTRL  | 3     |
| LUT1      | 1     |
| BUFGCE    | 1     |

### Synthesis Summary
- **Tool Version**: Vivado 2024.2
- **Device**: xck26-sfvc784-2LV-c
- **Runtime**: 37 seconds (CPU), 35 seconds (elapsed)
- **Memory**: Peak 2018.637 MB
- **Warnings**: 1920 critical warnings, 95 warnings
- **Errors**: 0
- **Unisim Transformations**: BUFG → BUFGCE (1), IBUF → IBUF/IBUFCTRL/INBUF (3)

## Constraints
Timing and I/O constraints are defined in:
- `synth/LSTM_cell.xdc`: Specifies clock period and I/O pin assignments.

Add this file to the Vivado project under Constraints to ensure proper synthesis and implementation.

## Block Diagrams and Timing
Documentation images are provided in the `doc/` directory:
- `block_diagram.png`: High-level architecture of the LSTM cell.
- `fsm_diagram.png`: State machine transitions for control logic.
- `timing_waveform.png`: Timing diagram showing handshake signals (`start`, `done`) and I/O behavior.

## Scripts
### Tcl
- `synthesis_lstm.tcl`: Automates synthesis and implementation in Vivado. Run with:
  ```tcl
  source synthesis_lstm.tcl
  ```

### Python
- `Untitled0.ipynb`: Jupyter notebook for generating `sigmoid_LUT.vh` and `tanh_LUT.vh`. Uses Python to compute 513 LUT entries for sigmoid and tanh in Q8.24 format.
- `.mem` files (`W_ih_dec.mem`, etc.) were generated from TSMAE’s Python scripts (not included).

## Low-Power Design Notes
- The design minimizes resource usage (e.g., no DSPs or Block RAMs) to reduce power consumption.
- Clock gating is not explicitly implemented but can be inferred by Vivado.
- For further power optimization, consider reducing `HIDDEN_SIZE` or `INPUT_SIZE`, or adding clock enables to submodules.

## Known Limitations
- **Weight Initialization**: Uses `$readmemh` to load weights from `.mem` files, which is simulation-friendly and synthesizable (inferred as ROM). However, this limits runtime weight updates.
- **No AXI Interface**: The design lacks a standard interface (e.g., AXI) for integration into larger systems.
- **Single-Step Operation**: Computes one LSTM step at a time, not time-unrolled for sequences.
- **High IOB Utilization**: The design exceeds the I/O capacity of the target FPGA (340.74%), requiring optimization or a larger device.

## Author
**Phan Chau Phong**
