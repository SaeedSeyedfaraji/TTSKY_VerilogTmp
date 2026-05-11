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

  wire rst;
  assign rst = ~rst_n;

  assign uo_out  = 8'b0000_0000;
  assign uio_out = 8'b0000_0000;
  assign uio_oe  = 8'b0000_0000;

  wire _unused = &{ui_in, uio_in, ena, clk, rst, 1'b0};

endmodule
