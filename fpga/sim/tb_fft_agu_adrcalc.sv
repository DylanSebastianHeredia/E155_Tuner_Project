`timescale 1ns/1ps

module tb_fft_agu_adrcalc;

   // Parameters
   localparam int M = 9;
   localparam int width = 16;

   // DUT I/O
   logic [M-1:0] level;
   logic [M-1:0] index;

   logic [M-1:0] adr_A;
   logic [M-1:0] adr_B;
   logic [M-2:0] twiddle_adr;

   // Instantiate DUT
   fft_agu_adrcalc #(.width(width), .M(M)) dut (
      .level(level),
      .index(index),
      .adr_A(adr_A),
      .adr_B(adr_B),
      .twiddle_adr(twiddle_adr)
   );

   initial begin
      $display(" FFT AGU ADDRESS CALC TB START ");

      // Sweep levels 0–8
      for (int lvl = 0; lvl < 9; lvl++) begin
         level = lvl;
         $display("\n LEVEL = %0d ", level);

         // Sweep some typical index values
         for (int idx = 0; idx < 16; idx += 1) begin
            index = idx;

            #1; // allow signals to update

            $display(
               "index=%0d | adr_A=%0d | adr_B=%0d | twiddle=%0d",
               index, adr_A, adr_B, twiddle_adr
            );
         end
      end

      $display("\n TB COMPLETE ");
      $finish;
   end

endmodule
