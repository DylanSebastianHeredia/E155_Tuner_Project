// Broderick Bownds & Sebastian Heredia


module fft_top
  #(parameter width=16, M=9)
   (input logic                clk,    // clock
    input logic                reset,  // reset
    input logic                start,  // pulse once loading is complete to begin calculation.
    input logic                load,   // when high, sample #`rd_adr` is read from `rd` to mem.
    input logic [M - 1:0]    rd_adr, // index of the input sample.
    input logic [2*width-1:0]  rd,     // read data in
    output logic [2*width-1:0] wd,     // complex write data out
    output logic               done);  // stays high when complete until `reset` pulsed.

   logic                       rd_sel, we0, we1;   // RAMx write enable
   logic [M - 1:0]           adr0_a, adr0_b, adr1_a, adr1_b;
   logic [M - 2:0]           twiddle_adr; // twiddle ROM adr
   logic [2*width-1:0]         twiddle, a, b, write_a, write_b, aout, bout;
   logic [2*width-1:0]         rd0_a, rd0_b, rd1_a, rd1_b, read_data;

   // load logic 
   assign read_data = rd; // complex input data real in top 16 bits, imaginary in bottom 16 bits
   assign write_a = load ? read_data : aout; // write ram0 with input data or BFU output
   assign write_b = load ? read_data : bout;

   // output logic
   assign wd = M[0] ? rd1_a : rd0_a;     // ram holding results depends on #fftLevels

   // ping-pong read (BFU input) logic
   assign a = rd_sel ? rd1_a : rd0_a;
   assign b = rd_sel ? rd1_b : rd0_b;

   // submodules   
   
   twiddle_ROM twiddlerom(
		.rd_clk_i(clk), 
        .rst_i(1'b0), 
        .rd_en_i(1'b1), 
        .rd_clk_en_i(1'b1), 
        .rd_addr_i(twiddle_adr),
        .rd_data_o(twiddle)) ;
		
   fft_control_unit  fft_cu(clk, reset, start, load, rd_adr, done, rd_sel, we0, we1, adr0_a, adr0_b, adr1_a, adr1_b, twiddle_adr);

   dual_RAM  ram0_a( 
		.wr_clk_i(clk), 
        .rd_clk_i(clk), 
        .rst_i(reset), 
        .wr_clk_en_i(1'b1), 
        .rd_en_i(we0), 
        .rd_clk_en_i(1'b1), 
        .wr_en_i(we0), 
        .wr_data_i(write_a), 
        .wr_addr_i(adr0_a), 
        .rd_addr_i(adr0_a), 
        .rd_data_o(rd0_a) );
		
   dual_RAM  ram0_b( 
		.wr_clk_i(clk), 
        .rd_clk_i(clk), 
        .rst_i(reset), 
        .wr_clk_en_i(1'b1), 
        .rd_en_i(we0), 
        .rd_clk_en_i(1'b1), 
        .wr_en_i(we0), 
        .wr_data_i(write_b), 
        .wr_addr_i(adr0_b), 
        .rd_addr_i(adr0_b), 
        .rd_data_o(rd0_b) );
	
	dual_RAM  ram1_a( 
		.wr_clk_i(clk), 
        .rd_clk_i(clk), 
        .rst_i(reset), 
        .wr_clk_en_i(1'b1), 
        .rd_en_i(we1), 
        .rd_clk_en_i(1'b1), 
        .wr_en_i(we1), 
        .wr_data_i(aout), 
        .wr_addr_i(adr1_a), 
        .rd_addr_i(adr1_a), 
        .rd_data_o(rd1_a));
		
	dual_RAM  ram1_b( 
		.wr_clk_i(clk), 
        .rd_clk_i(clk), 
        .rst_i(reset), 
        .wr_clk_en_i(1'b1), 
        .rd_en_i(we1), 
        .rd_clk_en_i(1'b1), 
        .wr_en_i(we1), 
        .wr_data_i(bout), 
        .wr_addr_i(adr1_b), 
        .rd_addr_i(adr1_b), 
        .rd_data_o(rd1_b));
   

   fft_butterfly fft_bfu(twiddle, a, b, aout, bout);

endmodule


