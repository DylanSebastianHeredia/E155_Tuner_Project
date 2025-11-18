// Broderick Bownds & Sebastian Heredia


module fft_top
  #(parameter width=16, M=5)
   (input logic                clk,    // clock
    input logic                reset,  // reset
    input logic                start,  // pulse once loading is complete to begin calculation.
    input logic                load,   // when high, sample #`rd_adr` is read from `rd` to mem.
    input logic [M - 1:0]    rd_adr, // index of the input sample.
    input logic [2*width-1:0]  rd,     // read data in
    output logic [2*width-1:0] wd,     // complex write data out
    output logic               done);  // stays high when complete until `reset` pulsed.

   logic                       rd_sel, we0, we1;   // RAMx write enable
   logic [M - 1:0]           adr0_a, adr0_b, adr1_a, adr1_b;
   logic [M - 2:0]           twiddle_adr; // twiddle ROM adr
   logic [2*width-1:0]         twiddle, a, b, write_a, write_b, aout, bout;
   logic [2*width-1:0]         rd0_a, rd0_b, rd1_a, rd1_b, read_data;

   // load logic 
   assign read_data = rd; // complex input data real in top 16 bits, imaginary in bottom 16 bits
   assign write_a = load ? read_data : aout; // write ram0 with input data or BFU output
   assign write_b = load ? read_data : bout;

   // output logic
   assign wd = M[0] ? rd1_a : rd0_a;     // ram holding results depends on #fftLevels

   // ping-pong read (BFU input) logic
   assign a = rd_sel ? rd1_a : rd0_a;
   assign b = rd_sel ? rd1_b : rd0_b;

   // submodules
   twiddle_ROM  twiddlerom(twiddle_adr, twiddle);
   fft_control_unit  fft_cu(clk, reset, start, load, rd_adr, done, rd_sel, we0, we1, adr0_a, adr0_b, adr1_a, adr1_b, twiddle_adr);

   dual_RAM  ram0(clk, we0, adr0_a, adr0_b, write_a, write_b, rd0_a, rd0_b);
   dual_RAM  ram1(clk, we1, adr1_a, adr1_b, aout, bout, rd1_a, rd1_b);

   fft_butterfly fft_bfu(twiddle, a, b, aout, bout);

endmodule

// Broderick Bownds & Sebastian Heredia
// brbownds@hmc.edu, dheredia@hmc.edu
// 11/12/2025

// fft_butterfly.sv
// This module contains the math portion of the FFT processor other than mult adn complex_mult
// and computes the imaginary and real parts of aout and bout to write into RAM0 and RAM1.

module fft_butterfly
	#(parameter bit_width = 16)
			(input logic signed  [2*bit_width - 1:0] twiddle,  // this is the input to the twiddle ROM's output will write up later
			 input logic signed  [2*bit_width - 1:0] a,
			 input logic signed  [2*bit_width - 1:0] b,
			 output logic signed [2*bit_width - 1:0] aout,
			 output logic signed [2*bit_width - 1:0] bout);
		
// These internal logic signals are the outputs when we multiply twiddle (wk)*b = temporary variables, 
// actually might not even need this because complex_mult takes care of it in its module
		logic signed [2*bit_width - 1:0] temp;
		logic signed [bit_width - 1:0] a_re, a_im, b_re, b_im, temp_re, temp_im;
		logic signed [bit_width - 1:0] aout_re, aout_im, bout_re, bout_im;

		complex_mult mult_bfu_1 (b, twiddle, temp); // output should be 2*bit_width where temp = {re,im}
	
		assign a_re = a[2*bit_width-1: bit_width];
		assign a_im = a[bit_width-1: 0];
		
		assign b_re = b[2*bit_width-1: bit_width];
		assign b_im = b[bit_width-1: 0];
		
		assign temp_re = temp[2*bit_width-1: bit_width];
		assign temp_im = temp[bit_width-1: 0];
		
// after initializing real and imaginary parts we can then move forward with
// the math portion of the BFU where aout = a + wk *b, bout = a - wk*b. but first to go in
// order we must compute tw * b where tw and b contain both real and imaginary parts. 
		
		// Then compute the adders/subtracters where we have 
		// aout_re = a_re + temp_re ;  aout_im = a_im + temp_im
		// bout_re = b_re - temp_re ;  bout_im = b_im - temp_im
		
		assign aout_re = a_re + temp_re;
		assign aout_im = a_im + temp_im;
		
		assign bout_re = a_re - temp_re;
		assign bout_im = a_im - temp_im;
		
		// cacanate 
		assign aout = {aout_re, aout_im};
		assign bout = {bout_re, bout_im};
		
endmodule
		
		
		
		

