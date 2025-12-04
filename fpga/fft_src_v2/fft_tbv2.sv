`timescale 1ns/1ps

module fft_tb;

    // -------------------------------------------------------------
    // DUT I/O
    // -------------------------------------------------------------
    logic clk;
    logic reset;
    logic sck;
    logic [31:0] sample_in;
    logic        sample_valid;

    logic done;
    logic sdo;

    // -------------------------------------------------------------
    // DUT instance
    // -------------------------------------------------------------
    fft dut (
        .clk(clk),
        .reset(reset),
        .sck(sck),
        .sample_in(sample_in),
        .sample_valid(sample_valid),
        .sdo(sdo),
        .done(done)
    );

    // -------------------------------------------------------------
    // Clock generation
    // -------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    assign sck = clk;

    // -------------------------------------------------------------
    // Memory
    // -------------------------------------------------------------
    localparam WIDTH = 32;
    localparam M = 9;

    logic [WIDTH-1:0] input_data   [0:(1<<M)-1];
    logic [WIDTH-1:0] expected_out [0:(1<<M)-1];

    integer f;

    // -------------------------------------------------------------
    // TB counters
    // -------------------------------------------------------------
    logic [9:0] idx;
    logic [9:0] out_idx;

    // -------------------------------------------------------------
    // Temp variables (must be at module scope for Radiant)
    // -------------------------------------------------------------
    logic [31:0] got;
    logic [31:0] want;

    logic signed [15:0] got_re;
    logic signed [15:0] got_im;
    logic signed [15:0] want_re;
    logic signed [15:0] want_im;

    // -------------------------------------------------------------
    // Reset + Init
    // -------------------------------------------------------------
    initial begin
        idx          = 0;
        out_idx      = 0;
        reset        = 1;
        sample_in    = 0;
        sample_valid = 0;

        $readmemh("C:/Users/broderickbowndz/Documents/E155 Labs/fft_DONE/fft_top/test_in (1).memh",
                  input_data);

        $readmemh("C:/Users/broderickbowndz/Documents/E155 Labs/fft_DONE/fft_top/gt_test_out (1).memh",
                  expected_out);

        f = $fopen("C:/Users/broderickbowndz/Documents/E155 Labs/fft_DONE/fft_top/test_out.memh", "w");

        #40;
        reset = 0;
    end

    // -------------------------------------------------------------
    // Drive test samples
    // -------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            idx          <= 0;
            sample_valid <= 0;
            sample_in    <= 0;
        end else begin
            idx <= idx + 1;

            if (idx < 512) begin
                sample_in    <= input_data[idx];
                sample_valid <= 1;
            end else begin
                sample_in    <= 0;
                sample_valid <= 0;
            end
        end
    end

    // -------------------------------------------------------------
    // Output collection + verification
    // Radiant requires all temps to be declared in module scope.
    // -------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            out_idx <= 0;

        end else if (done) begin

            if (out_idx < 512) begin

                got  = dut.spi_out.fft_data;
                want = expected_out[out_idx];

                got_re  = got[31:16];
                got_im  = got[15:0];
                want_re = want[31:16];
                want_im = want[15:0];

                $fwrite(f, "%h\n", got);

                if (got !== want) begin
                    $display("ERROR @ bin %0d: expected %h, got %h",
                              out_idx, want, got);

                    $display("       expected: %d + j%d", want_re, want_im);
                    $display("       got     : %d + j%d", got_re,  got_im);
                end

                out_idx <= out_idx + 1;

            end else begin
                $display("FFT Test Complete.");
                $fclose(f);
                $stop;
            end
        end
    end

endmodule
