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

  wire [1:0] mode;
  wire [5:0] value;

  wire [7:0] static_phase;
  wire [7:0] nco_step;
  reg  [7:0] nco_phase;

  wire [7:0] sin_static;
  wire [7:0] cos_static;
  wire [7:0] tan_static;
  wire [7:0] cot_static;

  wire [7:0] sin_nco;
  wire [7:0] cos_nco;

  assign mode  = ui_in[7:6];
  assign value = ui_in[5:0];

  // 6-bit user phase expanded to 8-bit phase.
  assign static_phase = {value, 2'b00};

  // NCO frequency-control word.
  assign nco_step = {value, 2'b00};

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      nco_phase <= 8'd0;
    else if (ena && (mode == 2'b10))
      nco_phase <= nco_phase + nco_step;
  end

  sine_lut_core sin_static_core (
      .phase  (static_phase),
      .result (sin_static)
  );

  sine_lut_core cos_static_core (
      .phase  (static_phase + 8'd64),
      .result (cos_static)
  );

  tan_lut_core tan_static_core (
      .phase  (static_phase),
      .result (tan_static)
  );

  cot_lut_core cot_static_core (
      .phase  (static_phase),
      .result (cot_static)
  );

  sine_lut_core sin_nco_core (
      .phase  (nco_phase),
      .result (sin_nco)
  );

  sine_lut_core cos_nco_core (
      .phase  (nco_phase + 8'd64),
      .result (cos_nco)
  );

  assign uo_out =
      (mode == 2'b00) ? sin_static :
      (mode == 2'b01) ? tan_static :
      (mode == 2'b10) ? sin_nco    :
                        nco_phase;

  assign uio_out =
      (mode == 2'b00) ? cos_static :
      (mode == 2'b01) ? cot_static :
      (mode == 2'b10) ? cos_nco    :
                        {mode, value};

  assign uio_oe = 8'hFF;

  wire _unused = &{uio_in, 1'b0};

endmodule

`default_nettype wire