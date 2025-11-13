module fft_top 
		#(parameter bit_width = 16,
		  parameter N = 512,
		  parameter M = log2(N))
		  
		  (input  logic clk, reset, start,
		   input  logic load,						// INPUT (Bus)
		   input  logic [M-1:0] rd_adr,
		   output logic done,
		   output logic [2*bit_width-1:0] wd);
		   

    // internal logic
	logic signed [2*bit_width-1:0] twiddle;
	logic [M-2:0] twiddle_adr
	logic [2*bit_width-1:0] wd_a, wd_b

    // Instantiate the reindex_bits module
    reindex_bits #(.L(11)) reindex_inst (
        .in(in), // connect the input
        .out(out) // connect the output
    );

    // You can assign values to 'in' for testing or further logic
    initial begin
        in = 11'b10101010101; // Example input value for testing
    end
	
twiddle_ROM   tw_ROM( twiddle_adr, twiddle);

fft_control_unit fft_cu();

dual_RAM ram0(clk, we, adr_a, adr_b, wd_a,	wd_b, rd_a,	rd_b); // when fully flushed out is when we will have different
															   // input/output names for both RAM0 and RAM1

dual_RAM ram1(clk, we, adr_a, adr_b, wd_a,	wd_b, rd_a,	rd_b);

endmodule
