// Top level module
module control (input logic 				clk, ram_clk, slow_clk, reset, start, load,
                       input logic [5:0] 		load_address,
                       input logic [31:0] 	data_in,
                       output logic 			done,
			output logic processing,
                       output logic [31:0] 	data_out);

   logic			    write_0, write_1;
   logic [5:0]		fft_level, butterfly_iter, address_0_a, address_0_b, write_address_0, address_1_a, address_1_b, write_address_1, out_address;
   logic [4:0]		twiddle_address;
   logic [31:0]	twiddle, a, b, a_out, b_out, write_data_a, write_data_b, write_data;
   logic [31:0]	read_data_0_a, read_data_0_b, read_data_1_a, read_data_1_b;

	// start 'processing' with a pulse from 'start'
	always_ff @(posedge slow_clk) begin
		if      (start) processing <= 1;
		else if (reset || done)  processing <= 0;
   end

	fft_counter counter(slow_clk, processing, reset, done,
							  fft_level, butterfly_iter);

	// output logic
   assign data_out = a;
	assign done = fft_level == 6;

	// output counter for address
	always_ff @(posedge slow_clk) begin
     if      (reset) out_address <= 0;
     else if (done)  out_address <= out_address + 1'b1;
	end

	fft_agu address_generator(load, processing, done, fft_level, butterfly_iter, load_address, out_address,
								 address_0_a, address_1_a, address_0_b, address_1_b, twiddle_address);

	// if load is high, write data_in to ram 0
   assign write_data_a = load ? data_in : a_out;
   assign write_data_b = load ? data_in : b_out;
   
   assign write_data = ram_clk ? write_data_a : write_data_b;
   assign write_address_0 = ram_clk ? address_0_a : address_0_b;
   assign write_address_1 = ram_clk ? address_1_a : address_1_b;

	ram ram0_a(clk, write_0, write_address_0, address_0_a, write_data,
				  read_data_0_a);
				
	ram ram0_b(clk, write_0, write_address_0, address_0_b, write_data,
				  read_data_0_b);

	ram ram1_a(clk, write_1, write_address_1, address_1_a, write_data,
				  read_data_1_a);
				
	ram ram1_b(clk, write_1, write_address_1, address_1_b, write_data,
				  read_data_1_b);

   // read from correct ram for butterfly input
   assign a = fft_level[0] ? read_data_1_a : read_data_0_a;
   assign b = fft_level[0] ? read_data_1_b : read_data_0_b;

	// get our twiddle factors
	twiddle_rom twiddle_gen(ram_clk, twiddle_address,
									twiddle);

	// perform the operation
	butterfly_unit butt(a, b, twiddle,
							  a_out, b_out);

	assign write_0 =  (fft_level[0] & processing) | load;
   assign write_1 =  ~fft_level[0] & processing;


endmodule

// Counts the level of the fft (log(N)) and the butterfly index (N/2)
module fft_counter (	input logic clk, processing, reset, done,
							output logic [5:0] fft_level, butterfly_iter);

   // count fftLevel and flyInd
   always_ff @(posedge clk) begin
      if (reset) begin
         fft_level <= 0;
         butterfly_iter <= 0;
      end

      else if(processing == 1 & ~done) begin
         if(butterfly_iter < 31) begin
            butterfly_iter <= butterfly_iter + 1'd1;
         end else begin
            butterfly_iter <= 0;
            fft_level <= (fft_level == 6) ? fft_level : fft_level + 1'd1;
         end
      end
   end

endmodule