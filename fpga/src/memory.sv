// Broderick Bownds & Sebastian heredia
// brbownds@hmc.edu, dheredia@hmc.edu
// November 11, 2025

// memory.sv coitains code for dual_RAM & twiddle_ROM for 512 point FFT
// Reads {Re, Im} pairs from a .vectors file (python-generated)

// Dual (2) memory banks must perform ping-pong actions since the pipline cannott read and write 
// to four different addresses ina single memory bank. Note: Single address line used for both reads
// and writes. So read (RAM0) on one memory and write (RAM1) on another, simultaneously.

// Will be used for both RAM0 and RAM1 (instantiated twice)

module dual_RAM
	#(parameter bit_width = 16,
	  parameter N = 32,								// 512 = 2^9 
	  parameter M = 5)							// M = log2(512) = 9
	 
	 (input logic 	clk, 
	  input logic 	we,									// Enable write & declare address vars
	  input logic 	[M-1:0] adr_a,						// 9-bits
	  input logic 	[M-1:0] adr_b,
	  
	  input logic 	[2*bit_width-1:0] wd_a,				// Write Data (INPUTS)
	  input logic 	[2*bit_width-1:0] wd_b,
	  
	  output logic 	[2*bit_width-1:0] rd_a,				// Read Data (OUPUTS)
	  output logic 	[2*bit_width-1:0] rd_b);
	  
	  logic [2*bit_width-1:0] ram [2*bit_width-1:0];	// "There are 32 rams with 32-bits each"

	always_ff@(posedge clk) begin
			if (we)
				ram[adr_a] <= wd_a;
				ram[adr_b] <= wd_b;
	end
	
	assign rd_a = ram[adr_a];
	assign rd_b = ram[adr_b];
	
endmodule

// Connect AGU twiddle_adr output to a W^k from the LUT
module twiddle_ROM
	#(parameter bit_width = 16,					    	// Re & Im components are 16-bits each
	  parameter N = 32, 
	  parameter M = 5)						    	// For 512pt FFT = 9 bits
	  
	 (input  logic [M-2:0] twiddle_adr,	        	   // Recall: 512/2 = 2 ^ 8 -> log2(2^8) = 8-bits (INPUT)
	  output logic [2*bit_width - 1:0] twiddle); 		// 32-bit = {Re, Im}							(OUTPUT)
	  
	// Number of W^k = N / 2 = 256 Re & Im terms
	logic [2*bit_width - 1:0]vectors[0:(N/2) - 1];		// "The first 256 elements in vectors are 32-bits wide" 
	
	// Load in data from python-generated LUT
	initial begin
		$readmemh("User/VECTOR_PATH.vectors", vectors);	// CHANGE to match correct path!
	end

	// Output the seleted twiddle based on twiddle address
	assign twiddle = vectors[twiddle_adr];

endmodule
