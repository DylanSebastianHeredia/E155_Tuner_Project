//------------------------------------------------------------------------------
// FFT system top
//   sample_in/sample_valid from I2S (via fft_master)
//   control  = your 512-pt FFT core
//   Now supports continuous frames by resetting the input buffer each time.
//------------------------------------------------------------------------------
module fft (
    input  logic        sck,           // SPI-out clock (we'll tie to clk for now)
    input  logic        reset,
    input  logic        clk,           // 48 MHz HFOSC clock

    input  logic [31:0] sample_in,     // 32-bit I2S left sample
    input  logic        sample_valid,  // 1-cycle pulse when sample_in is new

    output logic        sdo,
    output logic        done           // top-level "FFT frame processed"
);

    // -------------------------------------------------------------------------
    // Clock division for internal FFT timing
    // -------------------------------------------------------------------------
    logic [1:0] clk_counter = 2'd0;
    logic       ram_clk;
    logic       slow_clk;

    always_ff @(posedge clk)
        clk_counter <= clk_counter + 2'd1;

    assign ram_clk  = clk_counter[0];  // half-speed
    assign slow_clk = clk_counter[1];  // quarter-speed

    // -------------------------------------------------------------------------
    // Input buffer
    // -------------------------------------------------------------------------
    logic [31:0] data_to_fft;
    logic [8:0]  fft_read_addr;
    logic        buffer_full;
    logic        clear_frame;   // NEW: clears input buffer between frames

    fft_in_flop_noSPI inbuf (
        .clk          (clk),
        .reset        (reset),
        .sample_in    (sample_in),
        .sample_valid (sample_valid),
        .clear_frame  (clear_frame),       // NEW
        .fft_read_addr(fft_read_addr),
        .data_to_fft  (data_to_fft),
        .buffer_full  (buffer_full)
    );

    // -------------------------------------------------------------------------
    // FFT core (your control.sv)
    // -------------------------------------------------------------------------
    logic        fft_load;
    logic        fft_start;
    logic        fft_processing;
    logic        fft_done_core;
    logic [8:0]  fft_load_addr;
    logic [31:0] fft_data_out;

    control fft_core (
        .clk          (clk),
        .ram_clk      (ram_clk),
        .slow_clk     (slow_clk),
        .reset        (reset),
        .start        (fft_start),
        .load         (fft_load),
        .load_address (fft_load_addr),
        .data_in      (data_to_fft),
        .done         (fft_done_core),
        .processing   (fft_processing),
        .data_out     (fft_data_out)
    );

    // -------------------------------------------------------------------------
    // Output buffer + SPI-out (unchanged)
    // -------------------------------------------------------------------------
    logic [8:0]  fft_result_addr;
    logic [8:0]  spi_read_addr;
    logic [31:0] spi_read_data;
    logic        buffer_ready;
    logic        clear_buffer;

    fft_out_flop outbuf (
        .clk           (clk),
        .reset         (reset),
        .data_from_fft (fft_data_out),
        .fft_write_addr(fft_result_addr),
        .fft_write_en  (fft_done_core),
        .spi_read_addr (spi_read_addr),
        .spi_read_data (spi_read_data),
        .clear_buffer  (clear_buffer),
        .buffer_ready  (buffer_ready)
    );

    fft_spi_out spiout (
        .sck          (sck),
        .reset        (reset),
        .buffer_ready (buffer_ready),
        .spi_read_addr(spi_read_addr),
        .spi_read_data(spi_read_data),
        .clear_buffer (clear_buffer),
        .sdo          (sdo)
    );

    // -------------------------------------------------------------------------
    // Frame-level FSM: IDLE → LOAD → PROCESS → DONE_ST → IDLE (continuous)
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {IDLE, LOAD, PROCESS, DONE_ST} state_t;
    state_t    state;
    logic [8:0] load_ptr;

    always_ff @(posedge slow_clk or posedge reset) begin
        if (reset) begin
            state    <= IDLE;
            load_ptr <= 9'd0;
        end else begin
            case (state)

                IDLE: begin
                    load_ptr <= 9'd0;
                    // Wait for input buffer to fill with 512 samples
                    if (buffer_full)
                        state <= LOAD;
                end

                LOAD: begin
                    // Walk through 0..511 to feed FFT
                    if (load_ptr == 9'd511) begin
                        load_ptr <= 9'd0;
                        state    <= PROCESS;
                    end else begin
                        load_ptr <= load_ptr + 9'd1;
                    end
                end

                PROCESS: begin
                    load_ptr <= 9'd0;
                    if (fft_done_core)
                        state <= DONE_ST;
                end

                DONE_ST: begin
                    load_ptr <= 9'd0;
                    // Stay here while we clear the input buffer.
                    // Once buffer_full has been dropped back to 0,
                    // we can go back to IDLE and start filling again.
                    if (!buffer_full)
                        state <= IDLE;
                end

            endcase
        end
    end

    // Combinational control for FFT core + input RAM address
    always_comb begin
        fft_load      = (state == LOAD);
        fft_start     = (state == PROCESS);

        fft_read_addr = load_ptr;
        fft_load_addr = load_ptr;
    end

    // NEW: generate clear_frame for input buffer
    // While in DONE_ST, keep input buffer cleared (no accumulation).
    // Once we leave DONE_ST, clear_frame de-asserts and the next 512
    // samples will be captured.
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            clear_frame <= 1'b0;
        else
            clear_frame <= (state == DONE_ST);
    end

    // "done" indicates that a frame's FFT has completed (we're in DONE_ST)
    assign fft_result_addr = load_ptr;  // (unchanged – same address used for writes)
    assign done            = (state == DONE_ST);

endmodule
