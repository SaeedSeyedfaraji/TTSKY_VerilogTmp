/*
 * Copyright (c) 2026 Saeed Seyedfaraji
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

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

  wire        start;
  wire        mode;
  wire [7:0]  angle_in;
  wire [7:0]  result_out;
  wire        done;

  assign angle_in = ui_in;
  assign start    = uio_in[0];
  assign mode     = uio_in[1]; // 0 = sine, 1 = cosine

  sine_cos_lut core (
      .clk    (clk),
      .rst_n  (rst_n),
      .start  (start),
      .mode   (mode),
      .phase  (angle_in),
      .result (result_out),
      .valid  (done)
  );

  assign uo_out  = result_out;
  assign uio_out = {7'b0000000, done};

  // Only uio_out[0] is driven as output-valid/done.
  // uio[7:1] remain input-only from the user side.
  assign uio_oe  = 8'b0000_0001;

  wire _unused = &{ena, uio_in[7:2], 1'b0};

endmodule

`default_nettype wire