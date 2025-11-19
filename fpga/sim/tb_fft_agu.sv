`timescale 1ns/1ps

module tb_fft_agu;

    // Parameters
    localparam M = 9;
    localparam bit_width = 16;

    // Testbench signals
    logic clk;
    logic reset;
    logic enable;
    logic load;

    logic done;
    logic rd_sel;
    logic we0;
    logic we1;

    logic [M-1:0] adr_A;
    logic [M-1:0] adr_B;
    logic [M-2:0] twiddle_adr;

    // Instantiate DUT
    fft_agu #(.bit_width(bit_width), .M(M)) dut (
        .clk(clk),
        .enable(enable),
        .reset(reset),
        .load(load),
        .done(done),
        .rd_sel(rd_sel),
        .we0(we0),
        .we1(we1),
        .adr_A(adr_A),
        .adr_B(adr_B),
        .twiddle_adr(twiddle_adr)
    );

    // Clock generator (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus
    initial begin
        $display("===============================================");
        $display("         FFT AGU TESTBENCH STARTED");
        $display("===============================================");

        // Default values
        reset  = 1;
        enable = 0;
        load   = 0;

        // Hold reset for a few cycles
        #20;
        reset = 0;

        // Enable AGU operation
        enable = 1;

        // Run AGU until "done" goes high
        while (done == 0) begin
            @(posedge clk);

            $display("time=%0t | lvl=%0d  idx=%0d | A=%0d  B=%0d  tw=%0d | rd_sel=%0d we0=%0d we1=%0d done=%0d",
                $time,
                dut.level,
                dut.index,
                adr_A,
                adr_B,
                twiddle_adr,
                rd_sel,
                we0,
                we1,
                done
            );
        end

        // One extra cycle for clarity
        @(posedge clk);
        $display("===============================================");
        $display("               FFT AGU DONE");
        $display("===============================================");
        $finish;
    end

endmodule
