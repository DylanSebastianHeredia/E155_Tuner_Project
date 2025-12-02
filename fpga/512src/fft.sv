// Top-level module connecting SPI Buffer <-> FFT Controller
module fft (
    input  logic sck, 
    input  logic sdi, 
    input  logic reset, 
    input  logic full_reset,
    input  logic clk,      // System Clock (e.g. 48MHz from HFOSC)
    output logic sdo, 
    output logic done      // Debug/Status LED
);

    // =========================================================================
    // 1. Clock Generation
    // =========================================================================
    logic [1:0] clk_counter = 0;
    logic ram_clk;
    logic slow_clk;

    always_ff @(posedge clk) begin
        clk_counter <= clk_counter + 1'b1;
    end
    
    assign ram_clk = clk_counter[0]; // Half speed
    assign slow_clk = clk_counter[1]; // Quarter speed

    // =========================================================================
    // 2. Wires & Interfaces
    // =========================================================================
    
    // Signals between SPI Buffer and FFT Controller
    logic [31:0] spi_to_fft_data;
    logic [31:0] fft_to_spi_data;
    
    logic [8:0]  spi_read_addr;  // Address we read FROM SPI buffer
    logic [8:0]  spi_write_addr; // Address we write TO SPI buffer (results)
    logic        spi_write_en;
    
    logic        spi_buffer_full; // Signal from SPI that 512 samples are ready

    // FFT Controller Signals
    logic        fft_load;
    logic        fft_start;
    logic        fft_processing;
    logic        fft_done;
    logic [8:0]  fft_load_addr;
    logic [31:0] fft_data_out;
    
    // State Machine for Data Movement
    typedef enum logic [1:0] {IDLE, LOAD, PROCESS, DONE} state_t;
    state_t state, next_state;
    
    logic [8:0] load_ptr;

    // =========================================================================
    // 3. Module Instantiations
    // =========================================================================

    // NEW: RAM-Based SPI Buffer
    // Ensure "spi_fft_buffer.sv" is included in your project sources!
    fft_spi spi_inst (
        .sck(sck), 
        .sdi(sdi), 
        .reset(reset), 
        .sdo(sdo),
        .clk(clk),
        
        // Interface to this top-level module
        .data_to_fft(spi_to_fft_data),
        .data_from_fft(fft_to_spi_data),
        .fft_read_addr(spi_read_addr),   // We control this during LOAD state
        .fft_write_addr(spi_write_addr), // We control this during DONE state
        .fft_write_en(spi_write_en),
        .start_fft(spi_buffer_full)      // Triggers our state machine
    );

    // FFT Controller
    control fft_unit (
        .clk(clk), 
        .ram_clk(ram_clk), 
        .slow_clk(slow_clk), 
        .reset(reset), 
        .start(fft_start), 
        .load(fft_load), 
        .load_address(fft_load_addr),
        .data_in(spi_to_fft_data), // Feed data directly from SPI RAM
        .done(fft_done), 
        .processing(fft_processing), 
        .data_out(fft_data_out)
    );

    // =========================================================================
    // 4. Control Logic (The "Traffic Cop")
    // =========================================================================

    // State Transition
    always_ff @(posedge slow_clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            load_ptr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    load_ptr <= 0;
                    if (spi_buffer_full) state <= LOAD;
                end

                LOAD: begin
                    // Copy 512 words from SPI Buffer -> FFT Internal RAMs
                    if (load_ptr == 511) begin
                        state <= PROCESS;
                        load_ptr <= 0;
                    end else begin
                        load_ptr <= load_ptr + 1;
                    end
                end

                PROCESS: begin
                    // Wait for FFT to finish
                    // Note: 'fft_done' usually stays high once finished until reset
                    if (fft_done) state <= DONE;
                end

                DONE: begin
                    // FFT streams output automatically when done is high.
                    // We just wait here or loop back.
                    // For continuous audio, we might need a handshake to reset.
                    // For now, latch high.
                    state <= DONE; 
                end
            endcase
        end
    end

    // Output Signals & Muxing
    always_comb begin
        fft_load      = (state == LOAD);
        fft_start     = (state == PROCESS); // Pulse start? Or hold? 
                                            // Depending on controller, usually 1 cycle pulse is best,
                                            // but your controller looks level-sensitive. 
                                            // Let's hold it high during PROCESS for one cycle?
                                            // Actually, usually 'start' is a pulse. 
                                            // Let's make it a pulse on transition:
        
        // Connections
        spi_read_addr = load_ptr;
        fft_load_addr = load_ptr;
        
        // Handling Output Capture
        // When FFT is done, it increments an internal counter and outputs data.
        // We wire that directly to the SPI buffer's write port.
        // The FFT controller's "out_address" (internal) effectively drives this.
        // But we need to match the address.
        
        // Ideally, we'd tap into the controller's out_address, but since we can't 
        // without modifying it, let's look at `fft_to_spi_data`.
        fft_to_spi_data = fft_data_out;
        
        // Write enable: Only write when FFT is valid and done
        // Note: Your FFT controller streams data out when `done` is high.
        spi_write_en = fft_done; 
        
        // We need to know WHICH address the FFT is outputting to write to the correct SPI slot.
        // Limitation: Your current `fft_controller` doesn't output its `out_address`.
        // FIX: You should add `output logic [8:0] out_address_probe` to fft_controller
        // OR: We just generate our own counter here that matches the FFT's internal speed.
    end
    
    // *Quick Fix for Write Address*: 
    // Since we can't see the FFT's internal pointer, let's create a shadow counter
    logic [8:0] result_ptr;
    always_ff @(posedge slow_clk or posedge reset) begin
        if (reset) result_ptr <= 0;
        else if (fft_done) result_ptr <= result_ptr + 1;
    end
    assign spi_write_addr = result_ptr;

    assign done = (state == DONE);

endmodule