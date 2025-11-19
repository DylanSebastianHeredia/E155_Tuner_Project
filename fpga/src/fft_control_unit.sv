// Broderick Bownds & Sebastian Heredia 
// brbownds@hmc.edu, dheredia@hmc.edu
// 11/12/2025
// This module is the heart of the FFT processor where all enables and 
// addresses are sent out to the different modules 

module fft_control_unit 
        #(parameter bit_width = 16,
          parameter N = 512,
          parameter M = 9)
          
          (input  logic clk, reset,
           input  logic start, load,      // Note: Done is asserted when the computation is finished
           input  logic [M-1:0] rd_adr,
           output logic done, rd_sel, we0, we1,
           output logic [M-1:0] adr0_a, adr0_b, adr1_a, adr1_b,
		   output logic [M-2:0] twiddle_adr);

// Control Unit is responsible for all the sequential logic for performing the FFT (A.V. p.529)
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
