`timescale 1ns/1ps

module fft_master_tb;

    logic sd_in;
    logic reset;
    logic done;
    logic sdo;
    logic bck_i;
    logic lrck_i;
    logic sck;

    // Instantiate DUT 
    fft_master dut (
        .sd_in  (sd_in),
        .reset  (reset),
        .done   (done),
        .sdo    (sdo),
        .bck_i  (bck_i),
        .lrck_i (lrck_i)
    );

    initial begin
        $dumpfile("fft_master_tb.vcd");
        $dumpvars(0, fft_master_tb);
    end

    // RESET
    initial begin
        reset = 1;
        sd_in = 0;
        #2000;
        reset = 0;
        $display("[%0t] RESET RELEASED", $time);
    end

    // -----------------------------------------------------------------
    // I2S FAKE MIC DRIVER (this produces sample_valid activity)
    // -----------------------------------------------------------------
    logic [23:0] sample_value = 24'h200000;
    logic [5:0] bit_ptr = 0;

    always @(posedge bck_i) begin
        if (reset) begin
            bit_ptr <= 0;
            sd_in <= 0;
        end else begin
            sd_in <= sample_value[23 - bit_ptr];

            if (bit_ptr == 23) begin
                bit_ptr <= 0;
                sample_value <= sample_value + 24'h010000;
            end else begin
                bit_ptr <= bit_ptr + 1;
            end
        end
    end

    // -----------------------------------------------------------------
    // SPI CLOCK FOR OUTPUT CAPTURE
    // -----------------------------------------------------------------
    initial begin
        sck = 0;
        forever #50 sck = ~sck;  // 10 MHz SPI clock
    end

    // -----------------------------------------------------------------
    // CAPTURE SDO DATA (deserialize)
    // -----------------------------------------------------------------
    logic [31:0] shiftreg;
    int bitcount = 0;
    int out_idx = 0;
    logic [31:0] fft_bins [0:511];

    always @(posedge sck) begin
        shiftreg <= {shiftreg[30:0], sdo};
        bitcount++;

        if (bitcount == 31) begin
            fft_bins[out_idx] = {shiftreg[30:0], sdo};
            $display("FFT_BIN[%0d] = %h", out_idx, fft_bins[out_idx]);
            bitcount = 0;
            out_idx++;

            if (out_idx == 512) begin
                $display("ALL 512 FFT BINS RECEIVED!");
                #1000 $finish;
            end
        end
    end

    // -----------------------------------------------------------------
    // Safety timeout â€” MUST cover full-frame time
    // -----------------------------------------------------------------
    initial begin
        #20_000_000;  // 20ms
        $display("TIMEOUT â€” did not receive FFT frame");
        $finish;
    end

endmodule
