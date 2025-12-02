	// Takes in load, done, butterfly_iter, and fft_level,
// outputs read/write addresses
module fft_agu (input logic load, processing, done,
             input logic [8:0] fft_level,
			input logic [8:0] butterfly_iter, load_address, out_address,
             output logic [8:0] address_0_a, address_1_a, address_0_b, address_1_b,
             output logic [8:0] twiddle_address);

	// first deal with loading address
	logic [8:0] load_address_rev;
	reverse_bits load_logic(load_address, load_address_rev);

	// then deal with standard processing address
	logic [8:0] address_a, address_b;
	processing_agu standard_logic(fft_level, butterfly_iter,
											address_a, address_b, twiddle_address);

	// output address given as input

	// comb logic to choose from the addresses
	// if we're done, we output	
	// if we're loading, we use load addresses
	// otherwise, we use the standard addresses
	always_comb begin

		if (done) address_0_a = out_address;
		else if (load) address_0_a = load_address_rev;
		else address_0_a = address_a;

		if (load) address_0_b = load_address_rev;
		else address_0_b = address_b;

		if (done) address_1_a = out_address;
		else address_1_a = address_a;

		address_1_b = address_b;
		end
endmodule

module processing_agu (input logic [8:0] 	fft_level, 
					  input logic [8:0] butterfly_iter,
					  		  output logic [8:0] address_a, address_b,
					  		  output logic [8:0] twiddle_address);

	// intermediate for shifting
	logic [8:0] temp_a, temp_b; // Changed [5:0] -> [8:0]

	// must be signed for sign extending
   logic signed [8:0] mask, mask_shift;
   
   always_comb begin

		// j * 2
      temp_a = butterfly_iter << 1;

      address_a = ((temp_a << fft_level) | (temp_a >> (9 - fft_level))); 

		// j * 2 + 1
	  temp_b = temp_a + 9'b1;

      address_b = ((temp_b << fft_level) | (temp_b >> (9 - fft_level)));

		// zero out 6 - 1 - i
		// so five zeros minus fft_level
      mask = 9'b100000000; // Top bit of 9-bit number
	  mask_shift = mask >>> fft_level;

		// mask j
       twiddle_address = mask_shift[8:0] & butterfly_iter[8:0]; // Mask output
   end

endmodule

// reverse bits for address ordering
module reverse_bits (
    input logic [8:0] bits_in,
    output logic [8:0] bits_out
);
    // Manually reverse 9 bits
    assign bits_out = {bits_in[0], bits_in[1], bits_in[2], bits_in[3], 
                       bits_in[4], bits_in[5], bits_in[6], bits_in[7], bits_in[8]};
endmodule