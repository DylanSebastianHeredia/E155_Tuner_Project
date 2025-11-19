// Broderick Bownds & Sebastian Heredia 
// brbownds@hmc.edu, dheredia@hmc.edu
// 11/12/2025
// This module is the heart of the FFT processor where all enables and 
// addresses are sent out to the different modules 

module fft_control_unit 
        #(parameter bit_width = 16,
          parameter N = 512,
          parameter M = $clog2(N))
          
          (input  logic clk, reset,
           input  logic start, load,      // Note: Done is asserted when the computation is finished
           input  logic [M-1:0] rd_adr,
           output logic done, rd_sel, we0, we1,
           output logic [M-1:0] adr0_a, adr0_b, adr1_a, adr1_b,
		   output logic [M-2:0] twiddle_adr);

// Control Unit is responsibnel for all the sequential logic for perfomring the FFT (A.V. p.529)
 // pulsed start -> enable hold logic
   logic  enable;
   
   always_ff @(posedge clk) begin
		if (start) begin 
			enable <= 1;
		 end
		
		else if (done || reset) begin
			enable <= 0;
		end
	end

   // normal operation logic (generate butterfly addresses for RAM)
   logic [M-1:0]         adr_A, adr_B;
   logic                   we0_agu;
   
   fft_agu fft_agu(clk, enable, reset, load, done, rd_sel, we0_agu, we1, adr_A, adr_B, twiddle_adr);
   
   // load logic (generate bit-reversed indexes for RAM)
   logic [M - 1:0]     adr_load; // if loading, use addr from loader to load RAM0
	
 	// Instantiate the reindex_bits module
	reindex_bits reverse(rd_adr, adr_load);

   // done state/output logic (counter to address ram to write out on `rd`)
   logic [M-1:0]       out_idx;
   
   always_ff @(posedge clk)
     if      (reset) out_idx <= 0;
     else if (done)  out_idx <= out_idx + 1'b1;

   // assign output based on load/done state:
   // done state has priority and addresses ram0/ram1 a port for read on `wd`.
   //      (a mux in `fft` controls which ram `wd` reads from, depending on M)
   // load state has secondary priority and addresses ram0 a/b ports for write from `rd`.
   always_comb begin
      if      (done) adr0_a = out_idx;
      else if (load) adr0_a = adr_load;
      else           adr0_a = adr_A;
      
      if      (done) adr1_a = out_idx;
      else           adr1_a = adr_A;

      if      (load) adr0_b = adr_load;
      else           adr0_b = adr_B;

      adr1_b = adr_B;
      we0   = load | we0_agu;
   end
  
endmodule 

// address generation unit (AGU).
// counts the fft level and butterfly index within each level
// and generates ram addresses for each butterfly operation.
// also handles ping-pong control based on fft level.
module fft_agu
  #(parameter width=16, M=9)
   (input logic            clk,
    input logic            enable,
    input logic            reset,
    input logic            load,
    output logic           done,
    output logic           rd_sel,
    output logic           we0,
    output logic           we1,
    output logic [M-1:0] adr_A,
    output logic [M-1:0] adr_B,
    output logic [M-2:0] twiddle_adr);

   logic [M-1:0]         level = 0;
   logic [M-1:0]         index = 0;
   
   // count fftLevel and flyInd
   always_ff @(posedge clk) begin
      if (reset) begin
         level <= 0;
         index <= 0;
      end
      else if(enable === 1 & ~done) begin
         if(index < 2**(M - 1) - 1) begin
            index <= index + 1'd1;
         end else begin
            index <= 0;
            level <= level + 1'd1;
         end
      end
   end // always_ff @ (posedge clk)

   // sets done when we are finished with the FFT
   assign done = (level == (M));
   
   fft_agu_adrcalc adrcalc(level, index, adr_A, adr_B, twiddle_adr);

   // ping-pong logic that flips every level:
   assign rd_sel = level[0];
   assign we0 =   level[0] & enable;
   assign we1 =  ~level[0] & enable;

endmodule

// AGU address calculation unit.
// given FFT level and butterfly index, performs the proper
// rotations to generate the BFU input A and B addresses,
// and the masking to generate the twiddle addresses.

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
      twiddle_adr = sign_mask & index;     // twiddle_adr = 4-bits
   end
   
endmodule



