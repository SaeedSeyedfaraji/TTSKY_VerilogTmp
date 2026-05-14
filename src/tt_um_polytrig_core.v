/*
 * Copyright (c) 2026 Saeed Seyedfaraji
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// ============================================================
// TinyTapeout PolyTrig Core
// ------------------------------------------------------------
// ui_in[7:0]   = phase angle input
// uo_out[7:0]  = sine output
// uio_out[7:0] = cosine output
//
// Output format:
//   0   = -1
//   128 =  0
//   255 = +1
//
// Phase format:
//   0   =   0 degree
//   64  =  90 degree
//   128 = 180 degree
//   192 = 270 degree
//
// Cosine is generated as:
//   cos(x) = sin(x + 90 degree)
//          = sin(x + 64 phase counts)
// ============================================================

module tt_um_polytrig_core (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  wire [7:0] sin_out;
  wire [7:0] cos_out;

  sine_lut_core sin_core (
      .phase  (ui_in),
      .result (sin_out)
  );

  sine_lut_core cos_core (
      .phase  (ui_in + 8'd64),
      .result (cos_out)
  );

  assign uo_out  = sin_out;
  assign uio_out = cos_out;

  // All uio pins are outputs now, carrying cosine.
  assign uio_oe = 8'hFF;

  wire _unused = &{ena, clk, rst_n, uio_in, 1'b0};

endmodule


// ============================================================
// Quarter-Wave Sine LUT Core
// ------------------------------------------------------------
// Pure combinational sine approximation.
//
// Uses:
//   - 8-bit phase
//   - quarter-wave symmetry
//   - 17-point quarter-wave LUT
//   - 2-bit linear interpolation
// ============================================================

module sine_lut_core (
    input  wire [7:0] phase,
    output reg  [7:0] result
);

    reg [1:0] quadrant;
    reg [5:0] index;
    reg [5:0] quarter_pos;

    reg [3:0] seg_index;
    reg [1:0] frac;

    reg [6:0] y0;
    reg [6:0] y1;
    reg [6:0] delta;
    reg [6:0] interp_step;
    reg [6:0] mag;

    reg negative;

    // ========================================================
    // Quadrant decode and symmetry mapping
    // ========================================================

    always @(*) begin
        quadrant = phase[7:6];
        index    = phase[5:0];

        case (quadrant)

            2'b00: begin
                quarter_pos = index;
                negative    = 1'b0;
            end

            2'b01: begin
                quarter_pos = 6'd63 - index;
                negative    = 1'b0;
            end

            2'b10: begin
                quarter_pos = index;
                negative    = 1'b1;
            end

            default: begin
                quarter_pos = 6'd63 - index;
                negative    = 1'b1;
            end

        endcase
    end

    // ========================================================
    // Split quarter-wave position
    // ========================================================

    always @(*) begin
        seg_index = quarter_pos[5:2];
        frac      = quarter_pos[1:0];
    end

    // ========================================================
    // 17-point quarter-wave LUT
    // ========================================================

    always @(*) begin
        case (seg_index)

            4'd0: begin
                y0 = 7'd0;
                y1 = 7'd12;
            end

            4'd1: begin
                y0 = 7'd12;
                y1 = 7'd25;
            end

            4'd2: begin
                y0 = 7'd25;
                y1 = 7'd37;
            end

            4'd3: begin
                y0 = 7'd37;
                y1 = 7'd49;
            end

            4'd4: begin
                y0 = 7'd49;
                y1 = 7'd60;
            end

            4'd5: begin
                y0 = 7'd60;
                y1 = 7'd70;
            end

            4'd6: begin
                y0 = 7'd70;
                y1 = 7'd80;
            end

            4'd7: begin
                y0 = 7'd80;
                y1 = 7'd90;
            end

            4'd8: begin
                y0 = 7'd90;
                y1 = 7'd98;
            end

            4'd9: begin
                y0 = 7'd98;
                y1 = 7'd106;
            end

            4'd10: begin
                y0 = 7'd106;
                y1 = 7'd113;
            end

            4'd11: begin
                y0 = 7'd113;
                y1 = 7'd117;
            end

            4'd12: begin
                y0 = 7'd117;
                y1 = 7'd122;
            end

            4'd13: begin
                y0 = 7'd122;
                y1 = 7'd125;
            end

            4'd14: begin
                y0 = 7'd125;
                y1 = 7'd127;
            end

            default: begin
                y0 = 7'd127;
                y1 = 7'd127;
            end

        endcase
    end

    // ========================================================
    // Linear interpolation
    // ========================================================

    always @(*) begin
        delta = y1 - y0;

        case (frac)
            2'd0:    interp_step = 7'd0;
            2'd1:    interp_step = delta >> 2;
            2'd2:    interp_step = delta >> 1;
            default: interp_step = (delta >> 1) + (delta >> 2);
        endcase

        if (quarter_pos == 6'd63)
            mag = 7'd127;
        else
            mag = y0 + interp_step;
    end

    // ========================================================
    // Signed magnitude to unsigned output
    // ========================================================

    always @(*) begin
        if (negative)
            result = 8'd128 - {1'b0, mag};
        else
            result = 8'd128 + {1'b0, mag};
    end

endmodule

`default_nettype wire