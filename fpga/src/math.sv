// Broderick Bownds & Sebastian heredia
// brbownds@hmc.edu, dheredia@hmc.edu
// November 10, 2025

// math.sv contains all the math for the fft (explain why we are grouping the math components in one module)

// This module mult breaks down the basics of multiplying two fractionals 16-bit width numbers
// where the msb if the signed bit and the rest are fractional bits
module mult	
	#(parameter bit_width = 16)
		   (input logic signed  [bit_width - 1:0] a,
			input logic signed  [bit_width - 1:0] b,
			output logic signed [bit_width - 1:0] out);
			
		logic [2*bit_width - 1:0] mult_a_b;
		
		assign mult_a_b = a * b; // multiplying two fractional bits with width 16 bits to 
								// get out a 32-bit result then we scale back by 2^15 to get 
								// a number with 16-bit result and a rounding factor. 
		// assign mult_a_b = mult_a_b_unround[2*bit_width-2:bit_width-1];
		assign out = mult_a_b[2*bit_width-2:bit_width-1] + mult_a_b[bit_width - 2];
		
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
// Bit reversal 

module reindex_bits
	#(parameter L = 9) // instaniating L = layers and this is based on our FFT size where
						// 2^L = FFT size so therefore 2^(11) = 2048 FFT size
			(input logic [L - 1:0] in,
			output logic [L - 1:0] out);
			
	int i;
		always_comb begin
			for (i = 0; i < L; i++)
				out[i] = in[L-1-i];
		end
endmodule
			
			


