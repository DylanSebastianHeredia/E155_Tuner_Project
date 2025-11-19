`timescale 1ns/1ps

module math_tb;

    parameter W = 16;

    // Scalar mult I/O
    logic signed [W-1:0] a_scalar, b_scalar;
    logic signed [W-1:0] out_scalar;

    // Complex mult I/O
    logic signed [2*W-1:0] a_cplx, b_cplx;
    logic signed [2*W-1:0] out_cplx;

    // DUT Instantiations
    mult #(W) u_mult (
        .a(a_scalar),
        .b(b_scalar),
        .out(out_scalar)
    );

    complex_mult #(W) u_cmult (
        .a(a_cplx),
        .b(b_cplx),
        .out(out_cplx)
    );

    initial begin
        $display("--------- STARTING MATH TESTBENCH ---------");

    

        // 1) 0.5 * 0.5 = 0.25 â†’ 0x2000
        a_scalar = 16'h4000;
        b_scalar = 16'h4000;
        #1;
        assert(out_scalar === 16'h2000)
            else $error("mult FAIL: 0.5*0.5 expected 0x2000, got %h", out_scalar);

        // 2) -0.75 * 0.5 = -0.375 â†’ -0x3000
        a_scalar = -16'h6000;
        b_scalar =  16'h4000;
        #1;
        assert(out_scalar === -16'h3000)
            else $error("mult FAIL: -0.75*0.5 expected -0x3000, got %h", out_scalar);

        // 3) 0.9 * -0.4 = -0.36 â†’ -0x2E66
        a_scalar = 16'h7333;
        b_scalar = -16'h6666;
        #1;
        assert(out_scalar === -16'h2E66)
            else $error("mult FAIL: 0.9*(-0.4) expected -0x2E66, got %h", out_scalar);

        // 4) -1 * 1 = -1 â†’ 0x8000
        a_scalar = -16'h8000;
        b_scalar =  16'h7FFF;
        #1;
        assert(out_scalar === 16'h8000)
            else $error("mult FAIL: -1*1 expected 0x8000, got %h", out_scalar);

        // 5) 0.25 * 0.25 = 0.0625 â†’ 0x0800
        a_scalar = 16'h2000;
        b_scalar = 16'h2000;
        #1;
        assert(out_scalar === 16'h0800)
            else $error("mult FAIL: 0.25*0.25 expected 0x0800, got %h", out_scalar);
        //                 COMPLEX MULT TESTS
        // (0.5 + 0.25j)(0.5 - 0.25j) = 0.3125 + 0j
        a_cplx = {16'sh4000,  16'h2000};
        b_cplx = {16'sh4000, -16'h2000};
        #1;
        assert(out_cplx === {16'h2800, 16'sh0000})
            else $error("complex_mult FAIL test1: got %h", out_cplx);

        // (-0.5 + 0.5j)(0.25 + 0.25j) = -0.25 + 0j
        a_cplx = {-16'sh4000, 16'sh4000};
        b_cplx = { 16'sh2000, 16'sh2000};
        #1;
        assert(out_cplx === {-16'sh2000, 16'sh0000})
            else $error("complex_mult FAIL test2: got %h", out_cplx);

        // (-0.75 - 0.25j)(-0.5 + 0.25j) = 0.375 - 0.0625j
        a_cplx = {-16'sh6000, -16'sh2000};
        b_cplx = {-16'sh4000,  16'sh2000};
        #1;
        assert(out_cplx === {16'sh3000, -16'sh0800})
            else $error("complex_mult FAIL test3: got %h", out_cplx);

        // (0.5 + 0j)(0 + 0.5j) = 0 + 0.25j
        a_cplx = {16'sh4000, 16'sh0000};
        b_cplx = {16'sh0000, 16'sh4000};
        #1;
        assert(out_cplx === {16'sh0000, 16'sh2000})
            else $error("complex_mult FAIL test4: got %h", out_cplx);

        // magnitude stress test â€” imag must be 0
        a_cplx = {16'sh7AAB,  16'sh7AAB};
        b_cplx = {16'sh7AAB, -16'sh7AAB};
        #1;
        assert(out_cplx[15:0] === 16'sh0000)
            else $error("complex_mult FAIL test5: imag expected zero, got %h", out_cplx[15:0]);


        $display("ALL MATH TESTS PASSED");
        $stop;
    end

endmodule


