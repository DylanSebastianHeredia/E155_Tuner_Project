`timescale 1ns/1ps

module tb_fft_top;

   // Parameters
   localparam bit_width = 16;
   localparam M = 9;
   localparam N = 512;

   // DUT I/O
   logic clk;
   logic reset;
   logic start;
   logic load;
   logic [M-1:0] rd_adr;
   logic [2*bit_width-1:0] rd;
   logic [2*bit_width-1:0] wd;
   logic done;

   // Memory to hold input samples from file
   logic [2*bit_width-1:0] sample_mem [0:N-1];

   // Instantiate DUT
   fft_top #(bit_width, M, N) dut (
      .clk(clk),
      .reset(reset),
      .start(start),
      .load(load),
      .rd_adr(rd_adr),
      .rd(rd),
      .wd(wd),
      .done(done)
   );

   // Clock generator
   initial begin
      clk = 0;
      forever #5 clk = ~clk;
   end

   // Load file + stimulus
   initial begin
      // 1. Load input samples from file
      $display("Loading input samples...");
      // $readmemh("C:/Users/dheredia/Desktop/fft_top/source/fft_top/note_amplitude_hex_v2.txt", sample_mem);
	  $readmemh("C:/Users/dheredia/Desktop/fft_top/source/fft_top/sine_wave_100hz_hex.txt", sample_mem);

      // 2. Apply reset
      reset = 1;
      start = 0;
      load = 0;
      rd_adr = 0;
      rd = 0;
      #20;
      reset = 0;

      // 3. LOAD PHASE (write RAM0 with input samples)
      $display("Loading samples into FFT RAM...");

      for (int i = 0; i < N; i++) begin
         load = 1;
         rd_adr = i;
         rd = sample_mem[i];   // drive rd only when load=1
         #10;
      end

      load = 0;

      // 4. START FFT
      $display("Starting FFT computation...");
      start = 1;
      #10;
      start = 0;  // start is a pulse

      // 5. WAIT FOR DONE
      wait (done == 1);
      $display("FFT finished.");

      // 6. Read output (wd)
      $display("Dumping FFT output:");
      for (int k = 0; k < N; k++) begin
         #10;
         $display("out[%0d] = %h", k, wd);
      end

      $stop;
   end

endmodule
