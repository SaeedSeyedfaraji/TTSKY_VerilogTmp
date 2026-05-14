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

  wire       func_mode;
  wire [7:0] phase;

  wire [7:0] sin_out;
  wire [7:0] cos_out;
  wire [7:0] tan_out;
  wire [7:0] cot_out;

  assign func_mode = ui_in[7];

  // 7-bit phase expanded to 8-bit phase.
  // ui_in[6:0] = angle, ui_in[7] = mode.
  assign phase = {ui_in[6:0], 1'b0};

  sine_lut_core sin_core (
      .phase  (phase),
      .result (sin_out)
  );

  sine_lut_core cos_core (
      .phase  (phase + 8'd64),
      .result (cos_out)
  );

  tan_lut_core tan_core (
      .phase  (phase),
      .result (tan_out)
  );

  cot_lut_core cot_core (
    .phase  (phase),
    .result (cot_out)
    );

  // mode 0: sine / cosine
  // mode 1: tangent / cotangent
  assign uo_out  = func_mode ? tan_out : sin_out;
  assign uio_out = func_mode ? cot_out : cos_out;

  assign uio_oe = 8'hFF;

  wire _unused = &{ena, clk, rst_n, uio_in, 1'b0};

endmodule

`default_nettype wire