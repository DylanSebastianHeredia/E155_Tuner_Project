`timescale 1ns/1ps

module reindex_bits_tb;

    parameter L = 9;

    logic [L-1:0] in;
    logic [L-1:0] out;

    // DUT
    reindex_bits #(L) dut (
        .in(in),
        .out(out)
    );

    // Expected output function
    function automatic [L-1:0] reverse_bits(input [L-1:0] x);
        int i;
        for (i = 0; i < L; i++)
            reverse_bits[i] = x[L-1-i];
    endfunction

    initial begin
        $display("Starting reindex_bits Testbench");

        // Test 1
        in = 9'b000000001;
        #1;
        assert(out === reverse_bits(in))
            else $error("Test1 FAIL: in=%b out=%b exp=%b", in, out, reverse_bits(in));

        // Test 2
        in = 9'b101100111;
        #1;
        assert(out === reverse_bits(in))
            else $error("Test2 FAIL: in=%b out=%b exp=%b", in, out, reverse_bits(in));

        // Test 3
        in = 9'b111111111;
        #1;
        assert(out === reverse_bits(in))
            else $error("Test3 FAIL: in=%b out=%b exp=%b", in, out, reverse_bits(in));

        // Test 4
        in = 9'b010101010;
        #1;
        assert(out === reverse_bits(in))
            else $error("Test4 FAIL: in=%b out=%b exp=%b", in, out, reverse_bits(in));

        // Test 5
        in = $random;
        #1;
        assert(out === reverse_bits(in))
            else $error("Random FAIL: in=%b out=%b exp=%b", in, out, reverse_bits(in));

        $display("ALL reindex_bits TESTS PASSED");
        $stop;
    end

endmodule
