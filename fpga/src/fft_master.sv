// Broderick Bownds & Sebastian Heredia
// brbownds@hmc.edu, dheredia@hmc.edu
// 11/18/2025
//
// fft_master: top-level wrapper connecting I2S audio to FFT

module fft_master #(
    parameter bit_width = 16,
    parameter M = 9,
    parameter N = 512
)(
    input  logic clk, reset,
    input  logic start,      // start FFT
    input  logic load,       // load enable for FFT
    input  logic bck_i,      // I2S bit clock
    input  logic lrck_i,     // I2S left-right clock
    input  logic dat_i,      // I2S data line
    output logic done,        // FFT done signal
	output logic wd
);


    logic [23:0] left_o, right_o;

    // instantiate I2S receiver
    top_i2s_rx_module #(
        .FRAME_RES(32),
        .DATA_RES(24)
    ) i2s_rx (
        .bck_i(bck_i),
        .lrck_i(lrck_i),
        .dat_i(dat_i),
        .left_o(left_o),
        .right_o(right_o)
    );

	// fft input wiring
    // pack 24-bit left channel into 16-bit real, zero imag
    // truncating upper bits: left_o[23:8] -> 16 bits
    logic [2*bit_width-1:0] rd;
    assign rd = { left_o[23:8], 16'd0 }; 
    //            real part      imag=0

    // FFT read address (0:511)
    logic [M-1:0] rd_adr;

    // You increment rd_adr only when load=1
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rd_adr <= 0;
        end else if (load) begin
            rd_adr <= rd_adr + 1;
        end
    end

    // FFT output (not used yet)
    logic [2*bit_width-1:0] wd;

    
    // Instantiate FFT
    fft_top #(
        .bit_width(bit_width),
        .M(M),
        .N(N)
    ) fft_top (
        .clk(clk),
        .reset(reset),
        .start(start),
        .load(load),
        .rd_adr(rd_adr),
        .rd(rd),
        .wd(wd),
        .done(done)
    );

endmodule
