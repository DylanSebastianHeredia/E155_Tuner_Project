// Broderick Bownds & Sebastian Heredia
// brbownds@hmc.edu, dheredia@hmc.edu
// 11/29/2025
//
// fft_mag.sv
// Compute magnitude-squared of complex FFT output:
//   in = {Re, Im} (each signed bit_width)
//   out ≈ Re^2 + Im^2

module fft_mag2 #(parameter bit_width = 16)
	(
    input  logic [2*bit_width-1:0] in,   // {Re, Im}
    output logic [2*bit_width-1:0] out); // magnitude-squared (truncated)

    logic signed [bit_width-1:0] re;
    logic signed [bit_width-1:0] im;

    logic [2*bit_width-1:0] re_sq;
    logic [2*bit_width-1:0] im_sq;

    logic [2*bit_width:0] mag2_full;

    // flesh out input
    assign re = in[2*bit_width-1:bit_width];
    assign im = in[bit_width-1:0];

    // Square each component
    assign re_sq = re * re;   // positive
    assign im_sq = im * im;   // positive

    assign mag2_full = re_sq + im_sq;

    assign out = mag2_full[2*bit_width-1:0];

endmodule
