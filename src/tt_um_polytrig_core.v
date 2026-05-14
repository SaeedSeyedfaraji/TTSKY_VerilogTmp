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

    wire [1:0] mode  = ui_in[7:6];
    wire [5:0] value = ui_in[5:0];

    wire [1:0] nco_waveform = uio_in[1:0];
    wire [1:0] nco_amp      = uio_in[3:2];

    reg [5:0] nco_phase;

    wire [5:0] nco_step = value << 2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nco_phase <= 6'd0;
        end else if (ena && mode == 2'b10) begin
            nco_phase <= nco_phase + nco_step;
        end
    end

    wire [7:0] sin_static;
    wire [7:0] cos_static;
    wire [7:0] tan_static;
    wire [7:0] cot_static;

    wire [7:0] nco_sin;
    wire [7:0] nco_cos;

    sine_cos_lut sin_static_core (
        .phase(value),
        .func_sel(2'b00),
        .out(sin_static)
    );

    sine_cos_lut cos_static_core (
        .phase(value + 6'd16),
        .func_sel(2'b00),
        .out(cos_static)
    );

    sine_cos_lut tan_static_core (
        .phase(value),
        .func_sel(2'b01),
        .out(tan_static)
    );

    sine_cos_lut cot_static_core (
        .phase(value),
        .func_sel(2'b10),
        .out(cot_static)
    );

    sine_cos_lut nco_sin_core (
        .phase(nco_phase),
        .func_sel(2'b00),
        .out(nco_sin)
    );

    sine_cos_lut nco_cos_core (
        .phase(nco_phase + 6'd16),
        .func_sel(2'b00),
        .out(nco_cos)
    );

    function [7:0] scale_centered;
        input [7:0] x;
        input [1:0] amp;
        reg signed [9:0] delta;
        reg signed [9:0] scaled;
        begin
            delta = $signed({2'b00, x}) - 10'sd128;

            case (amp)
                2'b00: scaled = delta;                    // 100%
                2'b01: scaled = (delta >>> 1) + (delta >>> 2); // 75%
                2'b10: scaled = delta >>> 1;              // 50%
                default: scaled = delta >>> 2;            // 25%
            endcase

            scaled = scaled + 10'sd128;

            if (scaled < 0)
                scale_centered = 8'd0;
            else if (scaled > 255)
                scale_centered = 8'd255;
            else
                scale_centered = scaled[7:0];
        end
    endfunction

    function [7:0] triangle_wave;
        input [5:0] phase;
        reg [5:0] p;
        begin
            p = phase;

            if (p < 6'd16)
                triangle_wave = 8'd128 + (p << 3);
            else if (p < 6'd48)
                triangle_wave = 8'd255 - ((p - 6'd16) << 3);
            else
                triangle_wave = 8'd1 + ((p - 6'd48) << 3);
        end
    endfunction

    function [7:0] saw_wave;
        input [5:0] phase;
        begin
            saw_wave = {phase, 2'b00};
        end
    endfunction

    function [7:0] square_wave;
        input [5:0] phase;
        begin
            square_wave = phase[5] ? 8'd1 : 8'd255;
        end
    endfunction

    function [7:0] rectified_sine;
        input [7:0] x;
        reg signed [9:0] delta;
        reg [8:0] abs_delta;
        begin
            delta = $signed({2'b00, x}) - 10'sd128;

            if (delta < 0)
                abs_delta = -delta;
            else
                abs_delta = delta;

            if ((abs_delta << 1) > 9'd255)
                rectified_sine = 8'd255;
            else
                rectified_sine = (abs_delta << 1);
        end
    endfunction

    reg [7:0] nco_a_raw;
    reg [7:0] nco_b_raw;

    always @(*) begin
        case (nco_waveform)
            2'b00: begin
                nco_a_raw = nco_sin;
                nco_b_raw = nco_cos;
            end

            2'b01: begin
                nco_a_raw = triangle_wave(nco_phase);
                nco_b_raw = saw_wave(nco_phase);
            end

            2'b10: begin
                nco_a_raw = square_wave(nco_phase);
                nco_b_raw = square_wave(nco_phase + 6'd16);
            end

            default: begin
                nco_a_raw = rectified_sine(nco_sin);
                nco_b_raw = rectified_sine(nco_cos);
            end
        endcase
    end

    wire [7:0] nco_a = scale_centered(nco_a_raw, nco_amp);
    wire [7:0] nco_b = scale_centered(nco_b_raw, nco_amp);

    reg [7:0] out_a;
    reg [7:0] out_b;

    always @(*) begin
        case (mode)
            2'b00: begin
                out_a = sin_static;
                out_b = cos_static;
            end

            2'b01: begin
                out_a = tan_static;
                out_b = cot_static;
            end

            2'b10: begin
                out_a = nco_a;
                out_b = nco_b;
            end

            default: begin
                out_a = value;
                out_b = {nco_waveform, nco_amp, value[3:0]};
            end
        endcase
    end

    assign uo_out  = out_a;
    assign uio_out = out_b;
    assign uio_oe  = 8'hFF;

endmodule

`default_nettype wire