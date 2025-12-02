// Broderick Bownds & Sebastian Heredia
// brbownds@hmc.edu, dheredia@hmc.edu
// 12/1/2025

// fft_control.sv contains our fft_control unit and a counter so we
// count the levels and indices of the fft


module fft_control 
	#(parameter bit_width = 16, M = 9)
	(input  logic						clk,
	 input  logic						ram_clk, 
	 input  logic						slow_clk, 
	 input  logic                      reset, 
	 input  logic						start, 
	 input  logic                      load,
	 input  logic [M-1:0]				load_adr,
	 input  logic [2*bit_width-1:0] 	data_in,
	 output logic						done,
	 output logic                      processing,
	 output logic [2*bit_width-1:0] 	data_out);

   logic			        we0, we1;
   logic [M-1:0]		    level, index, adr0_a, adr0_b, wadr_0, adr1_a, adr1_b, wadr_1, out_adr;
   logic [M-2:0]		    twiddle_adr;
   logic [2*bit_width-1:0]	twiddle, a, b, aout, bout, wd_a, wd_b, wd;
   logic [2*bit_width-1:0]	rd0_a, rd0_b, rd1_a, rd1_b;

	always_ff @(posedge slow_clk) begin
		if      (start) processing <= 1;
		else if (reset || done)  processing <= 0;
   end

	fft_counter counter(slow_clk, processing, reset, done, level, index);

	// output logic
   assign data_out = a;
   assign done = (level == M); 

	// output counter for address
	always_ff @(posedge slow_clk) begin
		if      (reset) out_adr <= 0;
		else if (done)  out_adr <= out_adr + 1'b1;
	end

	fft_agu fft_agu(load, processing, done, level, index, load_adr, out_adr, adr0_a, adr0_b, adr1_a, adr1_b, twiddle_adr);

   assign wd_a = load ? data_in : aout;
   assign wd_b = load ? data_in : bout;
   
   assign wd     = ram_clk ? wd_a : wd_b;
   assign wadr_0 = ram_clk ? adr0_a : adr0_b;
   assign wadr_1 = ram_clk ? adr1_a : adr1_b;

	ram ram0_a(clk, we0, wadr_0, adr0_a, wd, rd0_a);
				
	ram ram0_b(clk, we0, wadr_0, adr0_b, wd, rd0_b);

	ram ram1_a(clk, we1, wadr_1, adr1_a, wd, rd1_a);
				
	ram ram1_b(clk, we1, wadr_1, adr1_b, wd, rd1_b);

   // read from correct ram for butterfly input
   assign a = level[0] ? rd1_a : rd0_a;
   assign b = level[0] ? rd1_b : rd0_b;

	// get our twiddle factors
	twiddle_ROM twiddle_gen(ram_clk, twiddle_adr, twiddle);

	// perform the butterfly operation
	fft_butterfly fft_bfu(twiddle, a, b, aout, bout);

	assign we0 =  (level[0] & processing) | load;
	assign we1 =  ~level[0] & processing;

endmodule

// Counts the level of the fft and the butterfly index M
module fft_counter 
	#(parameter M = 9)
   (input  logic clk,
	input  logic processing,
	input  logic reset, 
	input  logic done,
	output logic [M-1:0] level, 
	output logic [M-1:0] index);

   always_ff @(posedge clk) begin
      if (reset) begin
         level <= 0;
         index <= 0;
      end

else if(processing == 1 & ~done) begin
         if(index < 2**(M-1)-1) begin //255
               index <= index + 1'd1;
         end else begin
               index <= 0;
               // Stop counting until we reach level 9
               level <= (level == M) ? level : level + 1'd1; 
         end
      end
   end

endmodule
