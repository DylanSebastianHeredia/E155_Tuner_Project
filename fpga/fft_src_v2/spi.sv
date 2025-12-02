//------------------------------------------------------------------------------
// fft_in_flop_noSPI
// Receives 32-bit samples (already assembled from I2S left channel)
// Stores exactly 512 samples, then asserts buffer_full
// Cleared between frames by clear_frame from fft.sv
//------------------------------------------------------------------------------
module fft_in_flop_noSPI (
    input  logic        clk,
    input  logic        reset,

    // From I2S module / fft_master
    input  logic [31:0] sample_in,       // 32-bit audio sample
    input  logic        sample_valid,    // 1-cycle pulse per new sample

    // From FFT top: clear this buffer between frames
    input  logic        clear_frame,     // asserted while we want to reset buffer

    // To FFT controller
    input  logic [8:0]  fft_read_addr,   // address FFT uses during LOAD
    output logic [31:0] data_to_fft,     // data read by FFT

    output logic        buffer_full      // 512 samples collected
);

    logic [8:0] write_ptr;
    logic       ram_write_en;

    //-------------------------
    // 512 × 32-bit RAM
    //-------------------------
    ram input_ram (
        .clk           (clk),
        .write         (ram_write_en),
        .wadr (write_ptr),
        .radr  (fft_read_addr),
        .wd             (sample_in),
        .rd             (data_to_fft)
    );

    //-------------------------
    // Write logic
    //-------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset || clear_frame) begin
            write_ptr    <= 9'd0;
            buffer_full  <= 1'b0;
            ram_write_en <= 1'b0;
        end else begin
            ram_write_en <= 1'b0;

            // Only accept samples until we've filled 512 slots
            if (sample_valid && !buffer_full) begin
                ram_write_en <= 1'b1;

                if (write_ptr == 9'd511) begin
                    write_ptr   <= write_ptr; // stay at 511
                    buffer_full <= 1'b1;
                end else begin
                    write_ptr <= write_ptr + 9'd1;
                end
            end
        end
    end

endmodule



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
        .write(fft_write_en),
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


module fft_spi_out (
    input  logic        sck,
    input  logic        reset,

    input  logic        buffer_ready,
    output logic [8:0]  spi_read_addr,
    input  logic [31:0] spi_read_data,
    output logic        clear_buffer,

    output logic        sdo
);

    logic [31:0] shift_reg;
    logic [4:0]  bit_cnt;
    logic [8:0]  word_cnt;
    logic        buffer_active;

    assign spi_read_addr = word_cnt;

    always_ff @(posedge sck or posedge reset) begin
        if (reset) begin
            shift_reg     <= 32'd0;
            bit_cnt       <= 5'd0;
            word_cnt      <= 9'd0;
            buffer_active <= 1'b0;
            clear_buffer  <= 1'b0;
            sdo           <= 1'b0;
        end else begin
            clear_buffer <= 1'b0;

            if (!buffer_active) begin
                if (buffer_ready) begin
                    buffer_active <= 1'b1;
                    bit_cnt  <= 5'd0;
                    word_cnt <= 9'd0;
                    shift_reg <= spi_read_data;
                end
            end else begin
                sdo       <= shift_reg[31];
                shift_reg <= {shift_reg[30:0], 1'b0};

                if (bit_cnt == 5'd31) begin
                    bit_cnt <= 5'd0;

                    if (word_cnt == 9'd511) begin
                        word_cnt      <= 9'd0;
                        buffer_active <= 1'b0;
                        clear_buffer  <= 1'b1;
                    end else begin
                        word_cnt  <= word_cnt + 9'd1;
                        shift_reg <= spi_read_data;
                    end
                end else begin
                    bit_cnt <= bit_cnt + 5'd1;
                end
            end
        end
    end

endmodule
