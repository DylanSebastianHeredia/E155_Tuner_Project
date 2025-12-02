// Broderick Bownds & Sebastian Heredia 
// brbownds@hmc.edu, dheredia@hmc.edu
// 12/1/2025

// memory.sv contains the twiddle_ROM and RAM (dual port) made for single port
// introduces 1 cycle of lag so it can read the addresses then write, not at the same time and synchronize

module ram 
	 #(parameter bit_width=16, M=9)
(
    input  logic                     clk, 
    input  logic                     we,
    input  logic [M-1:0]       	   wadr, // write address
    input  logic [M-1:0]       	   radr, // read address
    input  logic [2*bit_width-1:0]   wd,  // write data
    output logic [2*bit_width-1:0]   rd   // read data
);
    logic [2*bit_width-1:0] mem [2**M-1:0]; 

   always_ff @(posedge clk)
		if (we) begin
			mem[wadr] <= wd;
		end

   always_ff @(posedge clk)
		rd <= mem[radr];

endmodule

// taken from sbox, synchronous - extra cycle of latency
module twiddle_ROM  
	#(parameter bit_width=16, M=9)
	 (input  logic                    clk,
	  input  logic [M-2:0]            twiddle_adr,
	  output logic [2*bit_width-1:0]  twiddle);
            
   // twiddle factors are generated with msb on left side
   logic [2*bit_width-1:0] mem [0:2**(M-1)-1];

   initial   $readmemh("C:/Users/broderickbowndz/Documents/E155 Labs/fft_DONE/fft_top/twiddle512.hex", mem);
	
	// Synchronous version
	always_ff @(posedge clk) begin
		twiddle <= mem[twiddle_adr];
	end

endmodule
