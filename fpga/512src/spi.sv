module fft_spi (
    input  logic sck, sdi, reset,
    output logic sdo,
    input  logic clk, // System clock
    
    // Interface to FFT Controller
    output logic [31:0] data_to_fft,
    input  logic [31:0] data_from_fft,
    input  logic [8:0]  fft_read_addr,  // Was [5:0], now [8:0]
    input  logic [8:0]  fft_write_addr, // Was [5:0], now [8:0]
    input  logic        fft_write_en,
    output logic        start_fft
);

    // 1. SPI Deserializer (Shift register for just 1 word)
    logic [31:0] spi_shift_reg;
    logic [4:0]  bit_cnt;
    logic [8:0]  word_cnt; // Counts up to 512 words
    logic        word_done;

    // 2. Input Buffer (RAM 512 x 32)
    logic        buf_we;
    logic [31:0] buf_q;
    // We reuse your existing 'ram' module but size it for 512
    ram input_ram (
        .clk(clk), 
        .write(buf_we),
        .write_address(word_cnt), 
        .read_address(fft_read_addr), 
        .d(spi_shift_reg), 
        .q(data_to_fft)
    );

    // SPI Input Logic
    always_ff @(posedge sck or posedge reset) begin
        if (reset) begin
            bit_cnt <= 0;
            word_cnt <= 0;
            start_fft <= 0;
        end else begin
            spi_shift_reg <= {spi_shift_reg[30:0], sdi};
            bit_cnt <= bit_cnt + 1;
            
            if (bit_cnt == 31) begin
                buf_we <= 1; // Pulse write to RAM
                word_cnt <= word_cnt + 1;
                if (word_cnt == 511) start_fft <= 1; // Trigger FFT when full
            end else begin
                buf_we <= 0;
            end
        end
    end
    
    // 3. Output Buffer (RAM 512 x 32)
    // The FFT controller writes results here, SPI reads them out
    logic [31:0] out_spi_data;
    ram output_ram (
        .clk(clk),
        .write(fft_write_en),
        .write_address(fft_write_addr),
        .read_address(word_cnt), // SPI reads using same counter
        .d(data_from_fft),
        .q(out_spi_data)
    );

    // Output Serialization (simplified)
    assign sdo = out_spi_data[31 - bit_cnt]; 

endmodule