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