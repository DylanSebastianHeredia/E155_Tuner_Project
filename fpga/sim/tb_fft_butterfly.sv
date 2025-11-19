`timescale 1ns/1ps

module fft_butterfly_tb;

    parameter W = 16;

    logic signed [2*W-1:0] a, b, twiddle;
    logic signed [2*W-1:0] aout, bout;

    fft_butterfly #(W) dut (
        .twiddle(twiddle),
        .a(a),
        .b(b),
        .aout(aout),
        .bout(bout)
    );

    initial begin
        // Test 1: twiddle = 1 + 0j → temp = b
        // a = (0.5 + 0.25j) = {0x4000, 0x2000}
        // b = (0.25 - 0.25j) = {0x2000, 0xE000}

        a       = {16'sh4000, 16'sh2000};
        b       = {16'sh2000, 16'shE000};
        twiddle = {16'sh7FFF, 16'sh0000};  // ~1.0 + 0j

        #1;
        // Expected:
        // aout = a + b  = (0.75, 0.0)        = {0x6000, 0x0000}
        // bout = a - b  = (0.25, 0.5)        = {0x2000, 0x4000}
        assert(aout === {16'sh6000, 16'sh0000})
            else $error("Test1 aout wrong: %h", aout);
        assert(bout === {16'sh2000, 16'sh4000})
            else $error("Test1 bout wrong: %h", bout);


        // ------------------------------------------------------
        // Test 2: twiddle = j = (0 + 1j)
        // b = (0.1 + 0.2j) → approx = {0x0CCD, 0x199A}
        // twiddle * b = -0.2 + 0.1j → {-0x199A, 0x0CCD}
        // ------------------------------------------------------

        a       = {16'shE000, 16'sh6000};    // a = (-0.25, 0.75)
        b       = {16'sh0CCD, 16'sh199A};    // b = (0.1, 0.2)
        twiddle = {16'sh0000, 16'sh7FFF};    // j

        #1;
        // Expected:
        // temp = (-0.2, 0.1) ≈ {0xE666, 0x0CCD}
        // aout = a + temp = (-0.45, 0.85) ≈ {0xC666, 0x6CCD}
        // bout = a - temp = (-0.05, 0.65) ≈ {0xF333, 0x5333}

        assert(aout === {16'shC666, 16'sh6CCD})
            else $error("Test2 aout wrong: %h", aout);

        assert(bout === {16'shF333, 16'sh5333})
            else $error("Test2 bout wrong: %h", bout);


        $display("All fft_butterfly tests passed.");
        $stop;
    end

endmodule
