// Broderick Bownds & Sebastian heredia
// brbownds@hmc.edu, dheredia@hmc.edu
// November 10, 2025

// math.sv contains all the math for the fft (explain why we are grouping the math components in one module)


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


// This is the module where the FOIL comes into play for multiplying complex numbers in the form of 
// (a_re + a_im) * (b_re +b_im) = (a_re * b_re + a_re * b_im + a_im * b_re + a_im * b_im) = out_re + out_im

module complex_mult
	#(parameter bit_width = 16)
			
			// Inputs a and b are 32-bits of the form x = {x_re, x_im}, where x_re and x_im are 16-bits wide
			(input logic signed [2*bit_width - 1:0] a,  
			 input logic signed [2*bit_width - 1:0] b, 
			 output logic signed [2*bit_width - 1:0] out);
	
	  logic signed [bit_width-1:0] a_re, b_re, a_im, b_im, out_re, out_im;		// All 16-bits wide
	  
	  // Assign Re and Im components from full a and b
	  assign a_re = a[2*bit_width - 1:bit_width];
	  assign a_im = a[bit_width-1:0];
	  assign b_re = b[2*bit_width - 1:bit_width];
	  assign b_im = b[bit_width-1:0];
	  
	  // Applying the mult module to carry out FOIL multiplication of Re and Im components 
	  logic signed [bit_width-1:0] c_re_re, c_im_im, c_re_im, c_im_re;
	  
	  mult mult_re_re (a_re, b_re, c_re_re);		// /(a_re) x (b_re) = c_re_re (which is 15-bits)
	  mult mult_im_im (a_im, b_im, c_im_im);
	  mult mult_re_im (a_re, b_im, c_re_im);
	  mult mult_im_re (a_im, b_re, c_im_re);
	  
	  // Combining like-terms for simplication 
	  assign out_re = (c_re_re) - (c_im_im);
	  assign out_im = (c_re_im) + (c_im_re);
	  
	  // Concatenation of Re and Im componets for the final complex output
	  assign out = {out_re, out_im};

endmodule



// This module mult breaks down the basics of multiplying two fractionals 16-bit width numbers
// where the msb if the signed bit and the rest are fractional bits
module mult	
    #(parameter bit_width = 16)
    (	input  logic signed [bit_width - 1:0] a,
        input  logic signed [bit_width - 1:0] b,
        output logic signed [bit_width - 1:0] out);

    logic signed [2*bit_width - 1:0] mult_a_b;

    // full 32-bit multiply of Q1.15 Ã— Q1.15 = Q2.30
    assign mult_a_b = a * b;

    // Correct Q1.15 result = bits [30:15], i.e. [2*bit_width-2 : bit_width-1]
    // Add rounding bit at [bit_width-2] = bit 14
    assign out = mult_a_b[2*bit_width-2 : bit_width-1] + mult_a_b[bit_width-2];

endmodule
