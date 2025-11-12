// Broderick Bownds & Sebastian heredia
// brbownds@hmc.edu, dheredia@hmc.edu
// November 11, 2025

// memory.sv contains code for dual_RAM and twiddle_ROM for 512 point FFT
// Reads {Re, Im} pairs from a .vectors file (python-generated)

// Dual (2) memory banks must perform ping-pong actions since the pipline cannott read and write 
// to four different addresses ina single memory bank. Note: Single address line used for both reads
// and writes. So read (RAM0) on one memory and write (RAM1) on another, simultaneously.

module dual_RAM
	#(parameter bit_width = 16,
	  parameter M = 9)
  
	  ////////////////////////////////////////////////////////
	  // START w/ Fig. 3 from A.V. and Fig. 5 from SLADE //
    ////////////////////////////////////////////////////////
  
	  (input logic clk,
	   input logic data_a,
	   input logic addr_a,
	   
	   
	
	
endmodule

// Connect AGU twiddle_addr output to a W^k from the LUT
module twiddle_ROM
	#(parameter bit_width = 16,					    	// Re & Im components are 16-bits each
	  parameter N = 512);						    	// For 512pt FFT
	 
	 (input logic [8 - 1:0] twiddle_addr;	        	// Recall: 512/2 = 2 ^ 8 -> log2(2^8) = 8-bits 	(INPUT)
	  output logic [2*bit_width - 1:0] twiddle); 		// 32-bit = {Re, Im}							(OUTPUT)
	  
	// Number of W^k = N / 2 = 256 Re & Im terms
	logic [2*bit_width - 1:0]vectors[0:(N/2) - 1];		// "The first 256 elements in vectors are 32-bits wide" 
	
	// Load in data from python-generated LUT
	initial begin
		$readmeab("User/VECTOR_PATH.vectors", vectors);	// CHANGE to match correct path!
	end

	// Output the seleted twiddle based on twiddle address
	assign twiddle = vectors[twiddle_addr];

endmodule
