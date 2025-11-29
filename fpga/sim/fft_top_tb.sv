`timescale 1ns/1ps

module tb_fft_top;

   localparam bit_width = 16;
   localparam M = 9;
   localparam N = 512;

   logic clk;
   logic reset;
   logic start;
   logic load;
   logic [M-1:0] rd_adr;
   logic [2*bit_width-1:0] rd;
   logic [2*bit_width-1:0] wd;
   logic done;

   logic [2*bit_width-1:0] sample_mem [0:N-1];

   // DUT
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

   // Clock
   initial begin
      clk = 0;
      forever #5 clk = ~clk;
   end

   // Stimulus
   initial begin
      integer k;

      // Load input samples
      $display("Loading samples...");
      $readmemh("note_amplitude_hex_v2.txt", sample_mem);

      // Reset
      reset = 1;
      start = 0;
      load = 0;
      rd_adr = 0;
      rd = '0;
      repeat(3) @(posedge clk);
      reset = 0;

      // LOAD PHASE
      $display("Writing samples into RAM0...");
      for (k = 0; k < N; k++) begin
         @(posedge clk);
         load = 1;
         rd_adr = k;
         rd = sample_mem[k];
      end
      @(posedge clk);
      load = 0;
      rd = '0;        // <—— important cleanup

      // START FFT
      @(posedge clk);
      start = 1;
      @(posedge clk);
      start = 0;

      // WAIT FOR DONE
      wait(done);
      $display("FFT DONE asserted.");

      // *** GIVE THE RAM TIME TO OUTPUT VALID DATA ***
      @(posedge clk);
      @(posedge clk);

      // READ FFT OUTPUT
      $display("Dumping FFT output:");
      for (k = 0; k < N; k++) begin
         @(posedge clk);
         $display("out[%0d] = %h", k, wd);
      end

      $stop;
   end

endmodule
