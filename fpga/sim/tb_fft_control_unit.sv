`timescale 1ns/1ps

module tb_fft_control_unit;

    localparam bit_width = 16;
    localparam N = 512;
    localparam M = 9;

    // DUT I/O
    logic clk;
    logic reset;
    logic start;
    logic load; 
    logic [M-1:0] rd_adr;

    logic done;
    logic rd_sel;
    logic we0;
    logic we1;
    logic [M-1:0] adr0_a, adr0_b, adr1_a, adr1_b;
    logic [M-2:0] twiddle_adr;

    // Instantiate DUT
    fft_control_unit #(
        .bit_width(bit_width),
        .N(N),
        .M(M)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .load(load),
        .rd_adr(rd_adr),
        .done(done),
        .rd_sel(rd_sel),
        .we0(we0),
        .we1(we1),
        .adr0_a(adr0_a),
        .adr0_b(adr0_b),
        .adr1_a(adr1_a),
        .adr1_b(adr1_b),
        .twiddle_adr(twiddle_adr)
    );

    // Simple clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        $display("===== FFT CONTROL UNIT TESTBENCH START =====");

        // initial values
        reset = 1;
        start = 0;
        load  = 0;
        rd_adr = 0;

        // hold reset
        repeat(3) @(posedge clk);
        reset = 0;

        // --------------------------------------
        // 1. LOAD PHASE (bit-reversed indexing)
        // --------------------------------------
        load = 1;
        $display("Load phase starting...");

        // drive a few rd_adr values to check adr_load path
        rd_adr = 9'd5;  @(posedge clk);
        rd_adr = 9'd20; @(posedge clk);
        rd_adr = 9'd100;@(posedge clk);
        rd_adr = 9'd255;@(posedge clk);

        load = 0;

        // --------------------------------------
        // 2. START FFT — begins normal AGU operation
        // --------------------------------------
        $display("Starting FFT AGU...");
        start = 1; @(posedge clk);
        start = 0;

        // allow AGU to run for several cycles
        repeat(80) @(posedge clk);

        // --------------------------------------
        // 3. WAIT UNTIL DONE ASSERTS
        // --------------------------------------
        wait(done == 1);
        $display("FFT finished. Done asserted.");

        // --------------------------------------
        // 4. OUTPUT (done) PHASE
        // out_idx should increment and adr0_a/adr1_a should match it
        // --------------------------------------
        $display("Output drain phase starting...");
        repeat(20) @(posedge clk);

        $display("===== TESTBENCH COMPLETE =====");
        $finish;
    end

endmodule
