module fft_top ();

    // Declare the input and output for reindex_bits instance
    logic [10:0] in;  // input of 11 bits (since L = 11)
    logic [10:0] out; // output of 11 bits

    // Instantiate the reindex_bits module
    reindex_bits #(.L(11)) reindex_inst (
        .in(in), // connect the input
        .out(out) // connect the output
    );

    // You can assign values to 'in' for testing or further logic
    initial begin
        in = 11'b10101010101; // Example input value for testing
    end

endmodule

module fft_bfu
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
		logic signed [bit_width - 1:0] aout_re, aout_im, bout_re, bout_im,

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
		
		
		
		
		
		
		
		
		
		
