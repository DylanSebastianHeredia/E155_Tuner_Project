`timescale 1ns/1ps

module tb_i2s_left_only;

    // =============================================================
    // Parameters (match DUT)
    // =============================================================
    localparam FRAME_RES = 32;
    localparam DATA_RES  = 24;

    // =============================================================
    // DUT I/O
    // =============================================================
    logic bck_i;
    logic lrck_i;
    logic dat_i;

    logic [DATA_RES-1:0] left_o;
    logic [DATA_RES-1:0] right_o;

    // =============================================================
    // DUT Instantiation
    // =============================================================
    top_i2s_rx_module #(
        .FRAME_RES(FRAME_RES),
        .DATA_RES(DATA_RES)
    ) dut (
        .bck_i   (bck_i),
        .lrck_i  (lrck_i),
        .dat_i   (dat_i),
        .left_o  (left_o),
        .right_o (right_o)
    );

    // =============================================================
    // Clock: BCK
    // =============================================================
    initial bck_i = 0;
    always #10 bck_i = ~bck_i;   // 50 MHz BCK (fast enough for simulation)

    // =============================================================
    // LRCK = Constant LOW → LEFT CHANNEL ONLY
    // =============================================================
    initial lrck_i = 1'b0;   // mic left-channel mode

    // =============================================================
    // Send ONE left-channel I²S frame (32 bits with 24-bit data)
    // =============================================================

    task send_left_frame(input [23:0] left_data);
        integer bitpos;
        begin
            // Must send 32 bits (MSB first) due to FRAME_RES=32,
            // but only the upper 24 bits contain valid sample data.
            for (bitpos = FRAME_RES-1; bitpos >= 0; bitpos--) begin
                @(negedge bck_i);
                if (bitpos >= (FRAME_RES - DATA_RES))  
                    // Upper 24 bits → real audio data
                    dat_i = left_data[bitpos - (FRAME_RES - DATA_RES)];
                else
                    // Lower 8 bits → padding
                    dat_i = 1'b0;
            end
        end
    endtask

    // =============================================================
    // Test Stimulus
    // =============================================================
    initial begin
        // Dump waveforms
        $dumpfile("tb_i2s_left_only.vcd");
        $dumpvars(0, tb_i2s_left_only);

        dat_i = 0;
        #100;

        // Known test pattern
        $display("Sending left sample = 0xAABBCC");
        send_left_frame(24'hAABBCC);

        // GIVE DUT TIME TO LATCH
        repeat(10) @(posedge bck_i);

        // CHECK LEFT
        if (left_o !== 24'hAABBCC)
            $display("FAIL: left_o = %h expected AABBCC", left_o);
        else
            $display("PASS: left_o correctly received AABBCC");

        // CHECK RIGHT (should remain zero)
        if (right_o !== 24'h000000)
            $display("FAIL: right_o = %h but should be ZERO", right_o);
        else
            $display("PASS: right_o remains 0 as expected");

        $finish;
    end

endmodule
