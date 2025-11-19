`timescale 1ns/1ps

module tb_fft_top;

   localparam bit_width = 16;
   localparam M = 9;        // keep FFT small for simulation
   localparam N = 1 << M;   // = 32-pt FFT for testbench speed

   logic clk;
   logic reset;
   logic start;
   logic load;
   logic [M-1:0] rd_adr;
   logic [2*bit_width-1:0] rd;
   logic [2*bit_width-1:0] wd;
   logic done;

 
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


   initial begin
      clk = 0;
      forever #5 clk = ~clk;
   end


   integer i;

   initial begin
     
      reset = 1;
      start = 0;
      load  = 0;
      rd_adr = 0;
      rd = 0;

      // hold reset for a few clocks
      repeat (3) @(posedge clk);
      reset = 0;


      // load one sample per clock
      $display("=== LOADING INPUT DATA INTO RAM0 ===");

      for (i = 0; i < N; i = i + 1) begin
         @(posedge clk);
         
         load = 1;          // enable load
         rd_adr = i;        // address being written
         
         // example: real = i, imag = 0
         rd = {i[bit_width-1:0], {bit_width{1'b0}}};

         $display("LOAD: addr=%0d  real=%0d  imag=0", i, i);
      end

      @(posedge clk);
      load = 0; // stop loading

      // ---------------------------
      // 3. Pulse START to run FFT
      // ---------------------------
      @(posedge clk);
      $display("=== START FFT ===");
      start = 1;

      @(posedge clk);
      start = 0; // start is a pulse

      // ---------------------------
      // 4. WAIT FOR DONE
      // ---------------------------
      $display("RUNNING... waiting for DONE");

      wait(done == 1);

      $display("=== FFT COMPLETE ===");

      
      $display("=== READING FFT OUTPUT ===");

      for (i = 0; i < N; i = i + 1) begin
         @(posedge clk);
         $display("OUT %0d: wd = 0x%h (real=%0d imag=%0d)",
                  i,
                  wd,
                  wd[2*bit_width-1:bit_width],
                  wd[bit_width-1:0]);
      end

      $display("=== TESTBENCH FINISHED ===");
      $finish;
   end

endmodule
