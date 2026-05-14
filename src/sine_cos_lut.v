`default_nettype none

module sine_cos_lut (
    input  wire [5:0] phase,
    input  wire [1:0] func_sel,
    output reg  [7:0] out
);

    function [7:0] sin_quarter;
        input [3:0] idx;
        begin
            case (idx)
                4'd0:  sin_quarter = 8'd128;
                4'd1:  sin_quarter = 8'd140;
                4'd2:  sin_quarter = 8'd153;
                4'd3:  sin_quarter = 8'd165;
                4'd4:  sin_quarter = 8'd177;
                4'd5:  sin_quarter = 8'd189;
                4'd6:  sin_quarter = 8'd200;
                4'd7:  sin_quarter = 8'd211;
                4'd8:  sin_quarter = 8'd221;
                4'd9:  sin_quarter = 8'd230;
                4'd10: sin_quarter = 8'd238;
                4'd11: sin_quarter = 8'd245;
                4'd12: sin_quarter = 8'd250;
                4'd13: sin_quarter = 8'd253;
                4'd14: sin_quarter = 8'd255;
                4'd15: sin_quarter = 8'd255;
                default: sin_quarter = 8'd255;
            endcase
        end
    endfunction

    function [7:0] sine_value;
        input [5:0] p;
        reg [1:0] quadrant;
        reg [3:0] idx;
        reg [7:0] qval;
        begin
            quadrant = p[5:4];
            idx = p[3:0];

            case (quadrant)
                2'b00: begin
                    qval = sin_quarter(idx);
                    sine_value = qval;
                end

                2'b01: begin
                    qval = sin_quarter(4'd15 - idx);
                    sine_value = qval;
                end

                2'b10: begin
                    qval = sin_quarter(idx);
                    sine_value = 8'd256 - qval;
                end

                default: begin
                    qval = sin_quarter(4'd15 - idx);
                    sine_value = 8'd256 - qval;
                end
            endcase
        end
    endfunction

    function [7:0] tan_value;
        input [5:0] p;
        reg [3:0] idx;
        begin
            idx = p[3:0];

            if (p == 6'd0)
                tan_value = 8'd128;
            else if (p == 6'd8)
                tan_value = 8'd255;
            else if (p == 6'd16)
                tan_value = 8'd1;
            else if (p == 6'd24)
                tan_value = 8'd4;
            else begin
                case (idx)
                    4'd0:  tan_value = p[4] ? 8'd1 : 8'd128;
                    4'd1:  tan_value = p[4] ? 8'd4 : 8'd140;
                    4'd2:  tan_value = p[4] ? 8'd8 : 8'd153;
                    4'd3:  tan_value = p[4] ? 8'd16 : 8'd166;
                    4'd4:  tan_value = p[4] ? 8'd32 : 8'd181;
                    4'd5:  tan_value = p[4] ? 8'd48 : 8'd197;
                    4'd6:  tan_value = p[4] ? 8'd70 : 8'd216;
                    4'd7:  tan_value = p[4] ? 8'd96 : 8'd235;
                    4'd8:  tan_value = p[4] ? 8'd128 : 8'd255;
                    4'd9:  tan_value = p[4] ? 8'd160 : 8'd235;
                    4'd10: tan_value = p[4] ? 8'd186 : 8'd216;
                    4'd11: tan_value = p[4] ? 8'd208 : 8'd197;
                    4'd12: tan_value = p[4] ? 8'd224 : 8'd181;
                    4'd13: tan_value = p[4] ? 8'd240 : 8'd166;
                    4'd14: tan_value = p[4] ? 8'd248 : 8'd153;
                    default: tan_value = p[4] ? 8'd252 : 8'd140;
                endcase
            end
        end
    endfunction

    function [7:0] cot_value;
        input [5:0] p;
        reg [3:0] idx;
        begin
            idx = p[3:0];

            if (p == 6'd0)
                cot_value = 8'd255;
            else if (p == 6'd8)
                cot_value = 8'd252;
            else if (p == 6'd16)
                cot_value = 8'd128;
            else if (p == 6'd24)
                cot_value = 8'd4;
            else begin
                case (idx)
                    4'd0:  cot_value = p[4] ? 8'd128 : 8'd255;
                    4'd1:  cot_value = p[4] ? 8'd116 : 8'd252;
                    4'd2:  cot_value = p[4] ? 8'd103 : 8'd248;
                    4'd3:  cot_value = p[4] ? 8'd90  : 8'd240;
                    4'd4:  cot_value = p[4] ? 8'd76  : 8'd224;
                    4'd5:  cot_value = p[4] ? 8'd60  : 8'd208;
                    4'd6:  cot_value = p[4] ? 8'd40  : 8'd186;
                    4'd7:  cot_value = p[4] ? 8'd20  : 8'd160;
                    4'd8:  cot_value = p[4] ? 8'd4   : 8'd252;
                    4'd9:  cot_value = p[4] ? 8'd20  : 8'd235;
                    4'd10: cot_value = p[4] ? 8'd40  : 8'd216;
                    4'd11: cot_value = p[4] ? 8'd60  : 8'd197;
                    4'd12: cot_value = p[4] ? 8'd76  : 8'd181;
                    4'd13: cot_value = p[4] ? 8'd90  : 8'd166;
                    4'd14: cot_value = p[4] ? 8'd103 : 8'd153;
                    default: cot_value = p[4] ? 8'd116 : 8'd140;
                endcase
            end
        end
    endfunction

    always @(*) begin
        case (func_sel)
            2'b00: out = sine_value(phase);
            2'b01: out = tan_value(phase);
            2'b10: out = cot_value(phase);
            default: out = 8'd0;
        endcase
    end

endmodule

`default_nettype wire