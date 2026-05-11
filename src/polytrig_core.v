/*
 * Minimal PolyTrig core shell.
 * mode = 0: sin
 * mode = 1: cos
 */

`default_nettype none

module polytrig_core (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire       mode,
    input  wire [7:0] angle_in,
    output reg  [7:0] result_out,
    output reg        done
);

  reg [7:0] angle_reg;
  reg       mode_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      angle_reg  <= 8'd0;
      mode_reg   <= 1'b0;
      result_out <= 8'd0;
      done       <= 1'b0;
    end else begin
      done <= 1'b0;

      if (start) begin
        angle_reg <= angle_in;
        mode_reg  <= mode;

        // Temporary behavior:
        // sin mode returns angle itself
        // cos mode returns 127 as placeholder for cos(0) ~= 1.0
        if (mode == 1'b0)
          result_out <= angle_in;
        else
          result_out <= 8'd127;

        done <= 1'b1;
      end
    end
  end

  wire _unused = &{angle_reg, mode_reg, 1'b0};

endmodule