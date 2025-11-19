module fft_agu_adrcalc
  #(parameter width=16, M=9)
   (input logic  [M-1:0] level,
    input logic  [M-1:0] index,
    output logic [M-1:0] adr_A,
    output logic [M-1:0] adr_B,
    output logic [M-2:0] twiddle_adr);

   logic [M-1:0]         tempA, tempB, temptwiddle;
   logic signed [M-1:0]  mask, sign_mask; // signed for sign extension
   
   always_comb begin
      // implement the rotations with shifting:
      //     adrA = ROTATE_{M}(2*flyInd,     fftLevel)
      //     adrB = ROTATE_{M}(2*flyInd + 1, fftLevel)
      tempA = index << 1'd1;
      tempB = tempA  +  1'd1;
      adr_A  = ((tempA << level) | (tempA >> (M - level)));
      adr_B  = ((tempB << level) | (tempB >> (M - level)));

      // replication operator to create the mask that gets shifted
      // (mask out the  last n-1-i least significant bits of flyInd)
      mask       = {1'b1, {M-1{1'b0}} };
      sign_mask      = mask >>> level;
      temptwiddle = sign_mask & index;     // twiddle_adr // internal 
	  twiddle_adr = temptwiddle[7:0];
   end
   
endmodule