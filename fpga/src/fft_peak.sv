// Broderick Bownds & Sebastian Heredia
// 11/29/2025
//
// fft_peak.sv
// Tracks maximum magnitude bin during FFT and latches result on 'done'.
//
// Assumptions:
//   - load = 1 while FFT is outputting bins 0..N-1
//   - bin_index increments from 0 to N-1
//   - done pulses high for one cycle when FFT finishes

module fft_peak #(
    parameter N = 512,
    parameter bit_width = 16,
	parameter M = $clog2(N)
	
)(
    input  logic                     clk,
    input  logic                     reset,
    input  logic                     load,       // High during FFT streaming
    input  logic                     done,       // Pulses when FFT finishes
    input  logic [2*bit_width-1:0]   mag2,       // magnitude-squared
    input  logic [M-1:0]             bin_index,  // current FFT bin index
    output logic [M-1:0]             peak_bin,   // bin with largest magnitude
    output logic [2*bit_width-1:0]   peak_mag);  // largest magnitude

    logic [2*bit_width-1:0]   max_mag;
    logic [$clog2(N)-1:0]     max_bin;

    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            max_mag <= 0;
            max_bin <= 0;
        end
        else if (load) begin
            // Compare and update peak
            if (mag2 > max_mag) begin
                max_mag <= mag2;
                max_bin <= bin_index;
            end
        end
        else if (!load && !done) begin
            // Between frames but before done → hold max values
            max_mag <= max_mag;
            max_bin <= max_bin;
        end
    end

// Latch outputs when FFT marks completion
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            peak_mag <= 0;
            peak_bin <= 0;
        end
        else if (done) begin
            peak_mag <= max_mag;
            peak_bin <= max_bin;
        end
    end

endmodule
