// Broderick Bownds & Sebastian Heredia
// brbownds@hmc.edu, dheredia@hmc.edu
// 12/1/2025

// i2s_clkgen_bck.sv
// Generate I2S bit clock (BCK) from 48 MHz HFOSC
// Divide by 16 to 48 MHz / 16 = 3.0 MHz

module i2s_clkgen_bck #(
    parameter DIV = 16     // must be even
)(
    input  logic clk,      // master 48 MHz clock
    input  logic reset,
    output logic bck       // ~3 MHz output clock
);

    localparam HALF = DIV/2;

    logic [$clog2(HALF)-1:0] cnt = 0;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt <= 0;
            bck <= 0;
        end else begin
            if (cnt == HALF-1) begin
                cnt <= 0;
                bck <= ~bck;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

endmodule

// i2s_clkgen_lrck.sv
// Generate I2S LRCK from BCK
// LRCK = BCK / 64  with BCK=3MHz  LRCK = 46.875 kHz

module i2s_clkgen_lrck (
    input  logic bck,      // bit clock
    input  logic reset,
    output logic lrck      // 48 kHz output
);

    logic [5:0] cnt = 0;   // count 0 to 63

    always_ff @(posedge bck or posedge reset) begin
        if (reset) begin
            cnt  <= 0;
            lrck <= 0;
        end else begin
            if (cnt == 63) begin
                cnt  <= 0;
                lrck <= ~lrck;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

endmodule
