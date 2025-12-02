	// Takes in load, done, butterfly_iter, and fft_level,
// outputs read/write addresses
module fft_agu 
	#(parameter M = 9)
	(input  logic         load,
	 input  logic         processing, 
	 input  logic         done,
	 input  logic [M-1:0] level,
	 input  logic [M-1:0] index, load_adr, out_adr,
	 output logic [M-1:0] adr0_a, adr0_b, adr1_a, adr1_b,
	 output logic [M-2:0] twiddle_adr);

	// use our load addresses to then reindex
	logic [M-1:0] load_adr_rev;
	logic [M-1:0] adr_A, adr_B;

	reindex_bits reindex_bits(load_adr, load_adr_rev);

	// then deal with standard processing address
	fft_agu_adrcalc fft_agu_calc(level, index, adr_A, adr_B, twiddle_adr);

	// output address given as input

	// comb logic to choose from the addresses
	// if we're done, we output	
	// if we're loading, we use load addresses
	// otherwise, we use the standard addresses
	always_comb begin

		if (done) adr0_a = out_adr;
			else if (load) adr0_a = load_adr_rev;
				else adr0_a = adr_A;

		if (load) adr0_b = load_adr_rev;
			else adr0_b = adr_B;

		if (done) adr1_a = out_adr;
			else adr1_a = adr_A;

		adr1_b = adr_B;
		end
endmodule

module fft_agu_adrcalc
  #(parameter width=16, M=9)
   (input logic  [M-1:0] level,
    input logic  [M-1:0] index,
    output logic [M-1:0] adr_A,
    output logic [M-1:0] adr_B,
    output logic [M-2:0] twiddle_adr);

   logic [M-1:0]         tempA, tempB;
   logic signed [M-1:0]  mask, sign_mask; // signed for sign extension
   
   always_comb begin
      // implement the rotations with shifting:
      //     adrA = ROTATE_{M}(2*index,     level)
      //     adrB = ROTATE_{M}(2*index + 1, level)
      tempA = index << 1'd1;
      tempB = tempA  +  1'd1;
      adr_A  = ((tempA << level) | (tempA >> (M - level)));
      adr_B  = ((tempB << level) | (tempB >> (M - level)));

      // replication operator to create the mask that gets shifted
      // (mask out the  last n-1-i least significant bits of flyInd)
      mask        = {1'b1, {M-1{1'b0}}};
      sign_mask   = mask >>> level;
      twiddle_adr = sign_mask & index;     // twiddle_adr // internal 
   end
   
endmodule

// reverse bits for address ordering
module reindex_bits
	#(parameter M = 9) // instaniating L = layers and this is based on our FFT size where
						// 2^L = FFT size so therefore 2^(11) = 2048 FFT size
			(input logic [M - 1:0] in,
			output logic [M - 1:0] out);
	int i;
		always_comb begin
			for (i = 0; i < M; i++)
				out[i] = in[M-1-i];
		end
endmodule
