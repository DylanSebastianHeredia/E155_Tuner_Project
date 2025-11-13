// Broderick Bownds & Sebastian Heredia 
// brbownds@hmc.edu, dheredia@hmc.edu
// 11/12/2025
// This module is the heart of the FFT processor where all enables and 
// addresses are sent out to the different modules 

module fft_control_unit 
        #(parameter bit_width = 16,
          parameter N = 512,
          paramter M = log2(N))
          
          (input  logic clk, reset,
           input  logic start, done, load,
           input  logic [M-1:0] rd_adr,
           output logic done, rd_sel, we0, we1,
           output logic [M-1:0] adr0_a, adr0_b, adr1_a, adr1_b);




endmodule
