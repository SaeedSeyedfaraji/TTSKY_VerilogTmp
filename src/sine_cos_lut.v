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

    always @(*) begin
        seg_index = quarter_pos[5:2];
        frac      = quarter_pos[1:0];
    end

    always @(*) begin
        case (seg_index)
            4'd0:  begin y0 = 7'd0;   y1 = 7'd12;  end
            4'd1:  begin y0 = 7'd12;  y1 = 7'd25;  end
            4'd2:  begin y0 = 7'd25;  y1 = 7'd37;  end
            4'd3:  begin y0 = 7'd37;  y1 = 7'd49;  end
            4'd4:  begin y0 = 7'd49;  y1 = 7'd60;  end
            4'd5:  begin y0 = 7'd60;  y1 = 7'd70;  end
            4'd6:  begin y0 = 7'd70;  y1 = 7'd80;  end
            4'd7:  begin y0 = 7'd80;  y1 = 7'd90;  end
            4'd8:  begin y0 = 7'd90;  y1 = 7'd98;  end
            4'd9:  begin y0 = 7'd98;  y1 = 7'd106; end
            4'd10: begin y0 = 7'd106; y1 = 7'd113; end
            4'd11: begin y0 = 7'd113; y1 = 7'd117; end
            4'd12: begin y0 = 7'd117; y1 = 7'd122; end
            4'd13: begin y0 = 7'd122; y1 = 7'd125; end
            4'd14: begin y0 = 7'd125; y1 = 7'd127; end
            default: begin y0 = 7'd127; y1 = 7'd127; end
        endcase
    end

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

    always @(*) begin
        if (negative)
            result = 8'd128 - {1'b0, mag};
        else
            result = 8'd128 + {1'b0, mag};
    end

endmodule