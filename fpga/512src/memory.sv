// based on Edwards from Columbia and Harris from E85
// 6-bit addresses for 64-point FFT
// will introduce 1 cycle of lag
module ram (
    input logic          clk, write,
    input logic [8:0]    write_address, read_address, // Changed [5:0] -> [8:0]
    input logic [31:0]   d,
    output logic [31:0]  q
);
    logic [31:0] mem [511:0]; // Changed [63:0] -> [511:0]

   always_ff @(posedge clk)
		if (write) begin
			mem[write_address] <= d;
		end

   always_ff @(posedge clk)
		q <= mem[read_address];

endmodule

// taken from sbox, synchronous - extra cycle of latency
module twiddle_rom (input logic clk,
                    input logic [8:0] twiddle_address,
                    output logic [31:0] twiddle);
            
   // twiddle factors are generated with msb on left side
   logic [31:0] mem [0:255];

   initial   $readmemh("C:/Users/dheredia/Desktop/fft/source/impl_1/twiddle512.hex", mem);
	
	// Synchronous version
	always_ff @(posedge clk) begin
		twiddle <= mem[twiddle_address];
	end

endmodule
