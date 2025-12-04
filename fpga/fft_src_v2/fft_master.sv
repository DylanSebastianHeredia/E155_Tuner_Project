module fft_master (
	input logic sck,
    input  logic sd_in,
    input  logic reset,
	input  logic cs, // for the MCU Chip select
    output logic done,
    output logic sdo,
    output logic bck_i,
    output logic lrck_i,
	output logic LED0, LED1
);

    // ===========================================================
    // 48 MHz Internal Oscillator
    // ===========================================================
    logic clk;
    HSOSC #(.CLKHF_DIV("0b10")) hf_osc (
        .CLKHFPU (1'b1),
        .CLKHFEN (1'b1),
        .CLKHF   (clk)
    );

    // ===========================================================
    // I2S Clock Generators
    // ===========================================================

    // DO NOT redeclare bck_i or lrck_i here!
    // They are already outputs.

    // Generate 3 MHz BCK from 48 MHz
    i2s_clkgen_bck #(
        .DIV(16)               // 48 MHz / 16 = 3.0 MHz
    ) gen_bck (
        .clk   (clk),
        .reset (reset),
        .bck   (bck_i)
    );

    // Generate ~48 kHz LRCK from BCK
    i2s_clkgen_lrck gen_lrck (
        .bck   (bck_i),
        .reset (reset),
        .lrck  (lrck_i)
    );

    // ===========================================================
    // I2S Receiver (left only)
    // ===========================================================
    logic [23:0] left24;

    top_i2s_rx_module i2s_inst (
        .bck_i  (bck_i),
        .lrck_i (lrck_i),
        .dat_i  (sd_in),
        .left_o (left24),
        .right_o()
    );

    // ===========================================================
    // Sample Valid Detection
    // Synchronize left24 into clk domain
    // ===========================================================
    logic [23:0] left24_sync1, left24_sync2;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            left24_sync1 <= 0;
            left24_sync2 <= 0;
        end else begin
            left24_sync1 <= left24;
            left24_sync2 <= left24_sync1;
        end
    end

    logic sample_valid;
    assign sample_valid = (left24_sync1 != left24_sync2);

    // ===========================================================
    // Convert to 32-bit sample for FFT
    // ===========================================================
    logic [31:0] sample32;
    assign sample32 = {left24_sync2, 8'd0};

    // ===========================================================
    // FFT System
    // ===========================================================
    logic sdo_int;

    fft fft_inst (
        .sck          (sck),
        .reset        (reset),
		.cs           (cs),
        .clk          (clk),
        .sample_in    (sample32),
        .sample_valid (sample_valid),
        .sdo          (sdo_int),
        .done         (done)
    );
	assign LED0 = bck_i;
	assign LED1 = lrck_i;
    assign sdo = sdo_int;

endmodule


