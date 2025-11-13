module fft_top 
		#(parameter bit_width = 16,
		  parameter N = 512,
		  parameter M = log2(N))
		  
		  (input  logic clk, reset,
		   input  logic start, load,	// INPUT (Bus)
		   input  logic [M-1:0] rd_adr, // ? not sure if this is top level input
		   output logic done, // ?? top level output not sure
		   output logic [2*bit_width-1:0] write_data);

    // internal logic
	logic rd_sel, we0, we1;
	logic [M-2:0] twiddle_adr, adr0_a, adr0_b, adr1_a, adr1_b;
	logic signed [2*bit_width-1:0] twiddle;
	logic [2*bit_width-1:0] b_in, wd_a, wd_b, read_data, rd0_a, rd0_b, rd1_a, rd1_b;

	// instaniate modules
	fft_control_unit fft_cu(clk, reset, start, done, load, rd_adr, done, rd_sel, we0, we1, dr0_a, adr0_b, adr1_a, adr1_b);
	
	twiddle_ROM  tw_ROM( twiddle_adr, twiddle);

	fft_butterfly fft_bfu (twiddle, a, b, aout, bout);

	// when fully flushed out is when we will have different input/output names for both RAM0 and RAM1
	dual_RAM ram0(clk, we, adr_a, adr_b, wd_a,	wd_b, rd_a,	rd_b); 
	dual_RAM ram1(clk, we, adr_a, adr_b, wd_a,	wd_b, rd_a,	rd_b);

 	// Instantiate the reindex_bits module
    reindex_bits reindex (in, out);

	// different mux to choose different write_data + different read_data inside top level
	assign wd_a = load ? wd_a : read_data; // learn why we need read_data
	assign wd_b = load ? wd_b : read_data;

	assign b_in = rd_sel ? rd0_b : rd1_b;

	//output
	assign write_data = rd_sel ? rd0_a : rd0_b;

endmodule
