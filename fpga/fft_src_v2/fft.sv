//------------------------------------------------------------------------------
// fft.sv
// 512-point FFT Top-Level
// - Drives fft_control from the main clk domain
// - Uses sample_valid directly (also in clk domain)
//------------------------------------------------------------------------------

module fft (
    input  logic        sck,           // SPI clock from MCU
    input  logic        reset,
	input  logic        cs,
    input  logic        clk,           // 48 MHz HFOSC clock

    input  logic [31:0] sample_in,     // I2S audio sample (clk domain)
    input  logic        sample_valid,  // 1-cycle pulse per sample (clk domain)

    output logic        sdo,           // SPI data-out to MCU
    output logic        done           // Frame complete
);

    // -------------------------------------------------------------------------
    // Internal Clock Division (for fft_control / RAM)
    // -------------------------------------------------------------------------
    logic [1:0] clk_counter = 2'd0;
    logic       ram_clk;
    logic       slow_clk;

    always_ff @(posedge clk)
        clk_counter <= clk_counter + 2'd1;

    assign ram_clk  = clk_counter[0];  // 24 MHz
    assign slow_clk = clk_counter[1];  // 12 MHz

    // Data to FFT core is just the current sample (clk domain)
    logic [31:0] data_to_fft;
    assign data_to_fft = sample_in;

    // -------------------------------------------------------------------------
    // FFT Core Interface
    // -------------------------------------------------------------------------
    logic        fft_load;
    logic        fft_start;
    logic        fft_processing;
    logic        fft_done_core;
    logic [8:0]  fft_load_addr;
    logic [31:0] fft_data_out;

    fft_control fft_core (
        .clk          (clk),        // main control clock
        .ram_clk      (ram_clk),    // RAM clock
        .slow_clk     (slow_clk),   // slower datapath clock if needed
        .reset        (reset),
        .start        (fft_start),  // asserted in clk domain
        .load         (fft_load),   // asserted in clk domain
        .load_adr     (fft_load_addr),
        .data_in      (data_to_fft),
        .done         (fft_done_core),
        .processing   (fft_processing),
        .data_out     (fft_data_out)
    );

    // -------------------------------------------------------------------------
    // Output Buffer (FFT results â†’ SPI read path)
    // -------------------------------------------------------------------------
    logic [8:0]  fft_result_addr;
    logic [8:0]  spi_read_addr;
    logic [31:0] spi_read_data;
    logic        clear_buffer;

    fft_out_flop outbuf (
        .clk            (clk),
        .reset          (reset),
        .data_from_fft  (fft_data_out),
        .fft_write_addr (fft_result_addr),
        .fft_write_en   (fft_done_core),
        .spi_read_addr  (spi_read_addr),
        .spi_read_data  (spi_read_data),
        .clear_buffer   (clear_buffer),
        .buffer_ready   ()
    );

    // -------------------------------------------------------------------------
    // SPI Output Serializer
    // -------------------------------------------------------------------------
    spi_fft_out spi_out (
        .sck      (sck),
		.cs       (cs),
        .reset    (reset),
        .clk      (clk),
        .fft_data (spi_read_data),
        .spi_addr (spi_read_addr),
        .sdo      (sdo)
    );

    // =========================================================================
    //                    FRAME FSM (runs in clk domain)
    // IDLE â†’ LOAD â†’ PROCESS â†’ DONE_ST â†’ IDLE
    // =========================================================================

    typedef enum logic [1:0] {IDLE, LOAD, PROCESS, DONE_ST} state_t;
    state_t state, state_next;

    logic [8:0] load_ptr;         // 0..511
    logic       fft_start_pulse;

    // -------------------------------------------------------------------------
    // State register + LOAD pointer (clk domain)
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state    <= IDLE;
            load_ptr <= 9'd0;
        end else begin
            state <= state_next;

            // Increment load_ptr only when we are loading a sample
            if (state == LOAD && sample_valid) begin
                if (load_ptr == 9'd511)
                    load_ptr <= 9'd0;
                else
                    load_ptr <= load_ptr + 1'b1;
            end

            // Ensure pointer reset whenever we go back to IDLE
            if (state == IDLE)
                load_ptr <= 9'd0;
        end
    end

    // -------------------------------------------------------------------------
    // Next-state logic (clk domain)
    // -------------------------------------------------------------------------
    always_comb begin
        state_next = state;

        case (state)

            // Wait for the first new sample of the frame
            IDLE: begin
                if (sample_valid)
                    state_next = LOAD;
            end

            // Load 512 real samples (one per sample_valid pulse)
            LOAD: begin
                if (sample_valid && load_ptr == 9'd511)
                    state_next = PROCESS;
            end

            // FFT core computation
            PROCESS: begin
                if (!fft_processing)
                    state_next = DONE_ST;
            end

            // One-cycle "done" state, then go back to IDLE
            DONE_ST: begin
                //if (load_ptr == 9'd511)
				state_next = IDLE;
            end

        endcase
    end

    // -------------------------------------------------------------------------
    // Pulse START exactly once at LOAD â†’ PROCESS transition (clk domain)
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            fft_start_pulse <= 1'b0;
        else
            fft_start_pulse <= (state == LOAD && state_next == PROCESS);
    end

    assign fft_start = fft_start_pulse;

    // -------------------------------------------------------------------------
    // LOAD signal â€” pulse when we have a new sample to write
    // -------------------------------------------------------------------------
    assign fft_load      = (state == LOAD) && sample_valid;

    // -------------------------------------------------------------------------
    // Address wiring
    //   - During LOAD, we step through 0..511 in load_ptr
    //   - fft_load_addr drives the input write address into fft_control
    //   - fft_result_addr is still tied to load_ptr as a placeholder
    // -------------------------------------------------------------------------
    assign fft_load_addr   = load_ptr;
    assign fft_result_addr = load_ptr;   // OK for now; refine once you know
                                         // how fft_done_core behaves (per-bin vs per-frame)

    // -------------------------------------------------------------------------
    // Clear FFT output buffer when DONE_ST
    // -------------------------------------------------------------------------
    assign clear_buffer = (state == DONE_ST);

    // -------------------------------------------------------------------------
    // Done signal for top level
    // -------------------------------------------------------------------------
    assign done = (state == DONE_ST);

endmodule





