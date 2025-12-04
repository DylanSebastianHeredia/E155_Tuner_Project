
module fft_out_flop (
    input  logic        clk,
    input  logic        reset,

    input  logic [31:0] data_from_fft,
    input  logic [8:0]  fft_write_addr,
    input  logic        fft_write_en,

    input  logic [8:0]  spi_read_addr,
    output logic [31:0] spi_read_data,

    input  logic        clear_buffer,
    output logic        buffer_ready
);

    ram output_ram (
        .clk(clk),
        .we(fft_write_en),
        .wadr(fft_write_addr),
        .radr(spi_read_addr),
        .wd(data_from_fft),
        .rd(spi_read_data)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            buffer_ready <= 1'b0;
        else if (clear_buffer)
            buffer_ready <= 1'b0;
        else if (fft_write_en && fft_write_addr == 9'd511)
            buffer_ready <= 1'b1;
    end

endmodule


module spi_fft_out (
    input  logic        sck,        // SPI clock from MCU (master)
    input  logic        cs,         // ACTIVE LOW chip select from MCU
    input  logic        reset,
    input  logic        clk,        // system clock (unused)
    input  logic [31:0] fft_data,   // word from fft_out_flop
    output logic [8:0]  spi_addr,   // read address into fft_out_flop
    output logic        sdo         // goes to MCU MISO
);

    // =========================================================================
    // Internal
    // =========================================================================
    logic [31:0] shift_reg;
    logic [5:0]  bit_cnt;        // 0..31
    logic [8:0]  word_cnt;       // 0..511
    logic        sdo_reg;

    assign sdo      = (cs == 1'b0) ? sdo_reg : 1'b0;   // idle when CS high
    assign spi_addr = word_cnt;

    // =========================================================================
    // SINGLE always_ff for counters + shifting
    // =========================================================================
    always_ff @(posedge sck or posedge reset) begin
        if (reset) begin
            bit_cnt   <= 0;
            word_cnt  <= 0;
            shift_reg <= 0;

        end else if (cs == 1'b1) begin
            // CS high = NOT selected â†’ reset counters
            bit_cnt   <= 0;
            word_cnt  <= 0;

        end else begin
            // ========== CS LOW â†’ ACTIVE SPI TRANSFER ==========

            if (bit_cnt == 0) begin
                // load new 32-bit word from FFT buffer
                shift_reg <= fft_data;
                bit_cnt   <= 6'd31;

            end else begin
                shift_reg <= {shift_reg[30:0], 1'b0};
                bit_cnt   <= bit_cnt - 1;

                if (bit_cnt == 1)
                    word_cnt <= word_cnt + 1;
            end
        end
    end

    // =========================================================================
    // SHIFT OUT (negedge SCK ONLY when CS low)
    // =========================================================================
    always_ff @(negedge sck or posedge reset) begin
        if (reset)
            sdo_reg <= 0;
        else if (cs == 1'b0)
            sdo_reg <= shift_reg[31];
    end

endmodule



