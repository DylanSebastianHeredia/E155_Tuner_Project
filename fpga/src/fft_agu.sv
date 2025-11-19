
// Broderick Bownds & Sebastian Heredia
// address generation unit (AGU).
// counts the fft level and butterfly index within each level
// and generates ram addresses for each butterfly operation.
// also handles ping-pong control based on fft level.
module fft_agu
  #(parameter bit_width=16, M=9)
   (input logic            clk,
    input logic            enable,
    input logic            reset,
    input logic            load,
    output logic           done,
    output logic           rd_sel,
    output logic           we0,
    output logic           we1,
    output logic [M-1:0] adr_A,
    output logic [M-1:0] adr_B,
    output logic [M-2:0] twiddle_adr);

   logic [M-1:0]         level = 0;
   logic [M-1:0]         index = 0;
   
   // count fftLevel and flyInd
   always_ff @(posedge clk) begin
      if (reset) begin
         level <= 0;
         index <= 0;
      end
      else if(enable === 1 & ~done) begin
         if(index < 2**(M - 1) - 1) begin
            index <= index + 1'd1;
         end else begin
            index <= 0;
            level <= level + 1'd1;
         end
      end
   end // always_ff @ (posedge clk)

   // sets done when we are finished with the FFT
   assign done = (level == (M));
   
   fft_agu_adrcalc adrcalc(level, index, adr_A, adr_B, twiddle_adr);

   // ping-pong logic that flips every level:
   assign rd_sel = level[0];
   assign we0 =   level[0] & enable;
   assign we1 =  ~level[0] & enable;

endmodule

