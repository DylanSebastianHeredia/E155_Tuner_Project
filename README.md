# E155: Tuner Project - Broderick + Sebastian

This repository contains the SystemVerilog code necessary to run a 512-point 16-bit fixed-point FFT in Lattice Radiant on the Upduino v3.1 FPGA. This repository also contains code to run pitch detection and display functionality in Segger on the STM32L432KC MCU.

The main elements of the project live in fpga > fft_src_v2 and mcu. Before running the FFT, twiddle vectors must be generated using the genTwiddle.py script located at fpga > sim > twiddle. Notably code to verify the FFT in hardware, which was adapted from Alec Vercruysee's paper titled "A Tutorial-style Single-cycle Fast Fourier Transform Processor," can also be found in fpga > sim. 

DISCLAIMER: The FFT code has been fully verified in simulation; however, interfacing with the MCU via SPI has not been fully verified in simuation or hardware due to inability to collect data unsing the current INMP441 MEMs I2S microphone setup.
