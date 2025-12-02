// perform the butterfly arithmetic for a, b, and a twiddle
module butterfly_unit (input logic [31:0]    a, b, twiddle,
                       output logic [31:0]   a_out, b_out);

   logic signed [15:0] real_a, imag_a, real_bmult, imag_bmult, real_a_out, imag_a_out, real_b_out, imag_b_out;

   logic [31:0] b_mult;

   // get components of a
   assign real_a = a[31:16];
   assign imag_a = a[15:0];
   
   // do the complex multiplication
   complex_multiplier mult(b, twiddle, b_mult);

   // get components of b
   assign real_bmult = b_mult[31:16];
   assign imag_bmult = b_mult[15:0];

   assign real_a_out = real_a + real_bmult;
   assign imag_a_out = imag_a + imag_bmult;

   assign real_b_out = real_a - real_bmult;
   assign imag_b_out = imag_a - imag_bmult;

   // compose a
   assign a_out = {real_a_out, imag_a_out};

   // compose b
   assign b_out = {real_b_out, imag_b_out};
   
endmodule


// performs complex multiplication 
module complex_multiplier (input logic [31:0]   b, twiddle,
                           output logic [31:0]  out);

   logic signed [15:0] real_b, real_twiddle, imag_b, imag_twiddle, real_out, imag_out;

   assign real_b = b[31:16];
   assign imag_b = b[15:0];


   assign real_twiddle = twiddle[31:16];
   assign imag_twiddle = twiddle[15:0];

   // real computation
   logic signed [15:0] real_b_real_twiddle, imag_b_imag_twiddle;

   multiplier m_real (real_b, real_twiddle, real_b_real_twiddle);
   multiplier m_imag (imag_b, imag_twiddle, imag_b_imag_twiddle);

   assign real_out = (real_b_real_twiddle) - (imag_b_imag_twiddle);

   // imaginary computation
   logic signed [15:0] real_b_imag_twiddle, imag_b_real_twiddle;

   multiplier m_real_b (real_b, imag_twiddle, real_b_imag_twiddle);
   multiplier m_real_twiddle (imag_b, real_twiddle, imag_b_real_twiddle);

   assign imag_out = (real_b_imag_twiddle) + (imag_b_real_twiddle);

   assign out = {real_out, imag_out};

endmodule


// this module multiplies 16-bit a and b, and returns a 16-bit rounded output
module multiplier (input logic signed [15:0]    in1, in2,
                   output logic signed [15:0]   out);

   logic [31:0] result; // 16-bit times 16-bit makes 32-bit

   assign result = in1 * in2;

   // as long as inputs aren't maximally negative, we can throw out msb
   // throw out least significant 15 bits so our output fits
   // add msb of thrown out bits to improve accuracy
   assign out = result[30:15] + result[14];

endmodule