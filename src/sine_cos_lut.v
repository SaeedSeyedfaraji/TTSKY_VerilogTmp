`default_nettype none

module sine_lut_core (
    input  wire [7:0] phase,
    output reg  [7:0] result
);

    reg [1:0] quadrant;
    reg [5:0] index;
    reg [5:0] quarter_pos;
    reg [6:0] mag;
    reg       negative;

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
        case (quarter_pos)
            6'd0:  mag = 7'd0;
            6'd1:  mag = 7'd3;
            6'd2:  mag = 7'd6;
            6'd3:  mag = 7'd9;
            6'd4:  mag = 7'd12;
            6'd5:  mag = 7'd16;
            6'd6:  mag = 7'd19;
            6'd7:  mag = 7'd22;
            6'd8:  mag = 7'd25;
            6'd9:  mag = 7'd28;
            6'd10: mag = 7'd31;
            6'd11: mag = 7'd34;
            6'd12: mag = 7'd37;
            6'd13: mag = 7'd40;
            6'd14: mag = 7'd43;
            6'd15: mag = 7'd46;
            6'd16: mag = 7'd49;
            6'd17: mag = 7'd52;
            6'd18: mag = 7'd55;
            6'd19: mag = 7'd58;
            6'd20: mag = 7'd61;
            6'd21: mag = 7'd64;
            6'd22: mag = 7'd67;
            6'd23: mag = 7'd70;
            6'd24: mag = 7'd73;
            6'd25: mag = 7'd75;
            6'd26: mag = 7'd78;
            6'd27: mag = 7'd81;
            6'd28: mag = 7'd83;
            6'd29: mag = 7'd86;
            6'd30: mag = 7'd88;
            6'd31: mag = 7'd91;
            6'd32: mag = 7'd93;
            6'd33: mag = 7'd95;
            6'd34: mag = 7'd98;
            6'd35: mag = 7'd100;
            6'd36: mag = 7'd102;
            6'd37: mag = 7'd104;
            6'd38: mag = 7'd106;
            6'd39: mag = 7'd108;
            6'd40: mag = 7'd110;
            6'd41: mag = 7'd112;
            6'd42: mag = 7'd113;
            6'd43: mag = 7'd115;
            6'd44: mag = 7'd117;
            6'd45: mag = 7'd118;
            6'd46: mag = 7'd120;
            6'd47: mag = 7'd121;
            6'd48: mag = 7'd122;
            6'd49: mag = 7'd123;
            6'd50: mag = 7'd124;
            6'd51: mag = 7'd125;
            6'd52: mag = 7'd126;
            6'd53: mag = 7'd126;
            6'd54: mag = 7'd127;
            6'd55: mag = 7'd127;
            6'd56: mag = 7'd127;
            6'd57: mag = 7'd127;
            6'd58: mag = 7'd127;
            6'd59: mag = 7'd127;
            6'd60: mag = 7'd127;
            6'd61: mag = 7'd127;
            6'd62: mag = 7'd127;
            default: mag = 7'd127;
        endcase
    end

    always @(*) begin
        if (negative)
            result = 8'd128 - {1'b0, mag};
        else
            result = 8'd128 + {1'b0, mag};
    end

endmodule

`default_nettype wire