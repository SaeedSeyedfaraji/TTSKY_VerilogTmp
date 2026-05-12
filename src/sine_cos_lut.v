`default_nettype none

// ============================================================
// TinyTapeout PolyTrig Project
// ------------------------------------------------------------
// This module implements:
//
//   mode = 0  --> sine
//   mode = 1  --> cosine
//
// using:
//
//   - quarter-wave LUT
//   - quadrant symmetry reconstruction
//   - unsigned 8-bit output representation
//
// ------------------------------------------------------------
// Phase representation:
//
//   phase = 0     ->   0°
//   phase = 64    ->  90°
//   phase = 128   -> 180°
//   phase = 192   -> 270°
//
// Full scale:
//
//   256 steps = 360°
//
// ------------------------------------------------------------
// Output representation:
//
//   0     = minimum value (-1)
//   128   = zero crossing
//   255   = maximum value (+1)
//
// ------------------------------------------------------------
// Architecture:
//
//   Cycle 0:
//      sample phase/mode
//
//   Cycle 1:
//      LUT lookup + symmetry reconstruction
//
//   Cycle 2:
//      result valid
//
// ------------------------------------------------------------
// Cosine implementation:
//
//   cos(x) = sin(x + 90°)
//
// Since:
//
//   90° = 64 phase counts
//
// we simply add:
//
//   phase + 64
//
// ============================================================

module sine_cos_lut (

    // System clock
    input  wire       clk,

    // Active-low reset
    input  wire       rst_n,

    // Start pulse
    // When asserted, input phase/mode are sampled
    input  wire       start,

    // Function select:
    //   0 -> sine
    //   1 -> cosine
    input  wire       mode,

    // 8-bit phase input
    input  wire [7:0] phase,

    // 8-bit unsigned waveform output
    output reg  [7:0] result,

    // Output valid pulse
    output reg        valid
);

    // ========================================================
    // Internal Registers
    // ========================================================

    // Internal phase actually used by the LUT
    // For cosine:
    //    phase_used = phase + 64
    reg [7:0] phase_used;

    // Quadrant number:
    //
    //   00 -> Q0
    //   01 -> Q1
    //   10 -> Q2
    //   11 -> Q3
    //
    reg [1:0] quadrant;

    // Position inside quadrant
    reg [5:0] index;

    // Actual LUT address after symmetry mapping
    reg [5:0] lut_addr;

    // Sign flag:
    //
    //   0 -> positive
    //   1 -> negative
    //
    reg negative;

    // LUT magnitude:
    //
    //   0..127
    //
    // This stores ONLY magnitude.
    // Sign is reconstructed later.
    //
    reg [6:0] mag;

    // ========================================================
    // Stage 1
    // --------------------------------------------------------
    // Sample input phase/mode
    // Convert cosine into shifted sine phase
    // ========================================================

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            phase_used <= 8'd0;
            valid      <= 1'b0;

        end else begin

            // Valid follows start pulse
            valid <= start;

            if (start) begin

                // --------------------------------------------
                // Cosine:
                //
                //   cos(x) = sin(x + 90°)
                //
                // In 8-bit phase representation:
                //
                //   90° = 64
                // --------------------------------------------

                if (mode)
                    phase_used <= phase + 8'd64;

                // Pure sine
                else
                    phase_used <= phase;

            end
        end
    end

    // ========================================================
    // Quadrant Decode + Symmetry Reconstruction
    // --------------------------------------------------------
    //
    // We only store ONE quarter-wave:
    //
    //   0° -> 90°
    //
    // The remaining 3 quadrants are reconstructed
    // mathematically using symmetry.
    //
    // ========================================================

    always @(*) begin

        // Upper 2 bits define quadrant
        quadrant = phase_used[7:6];

        // Lower 6 bits define position inside quadrant
        index = phase_used[5:0];

        case (quadrant)

            // =================================================
            // Q0 : 0° -> 90°
            //
            // Rising positive waveform
            //
            // Use LUT directly
            // =================================================

            2'b00: begin

                lut_addr = index;
                negative = 1'b0;

            end

            // =================================================
            // Q1 : 90° -> 180°
            //
            // Falling positive waveform
            //
            // Mirror LUT address
            // =================================================

            2'b01: begin

                lut_addr = 6'd63 - index;
                negative = 1'b0;

            end

            // =================================================
            // Q2 : 180° -> 270°
            //
            // Falling negative waveform
            //
            // Direct LUT address
            // Negative sign
            // =================================================

            2'b10: begin

                lut_addr = index;
                negative = 1'b1;

            end

            // =================================================
            // Q3 : 270° -> 360°
            //
            // Rising negative waveform
            //
            // Mirrored LUT address
            // Negative sign
            // =================================================

            default: begin

                lut_addr = 6'd63 - index;
                negative = 1'b1;

            end
        endcase
    end

    // ========================================================
    // Quarter-Wave Sine Magnitude LUT
    // --------------------------------------------------------
    //
    // Stores only:
    //
    //   sin(0° -> 90°)
    //
    // scaled to:
    //
    //   0 -> 127
    //
    // ========================================================

    always @(*) begin

        case (lut_addr)

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
            6'd33: mag = 7'd96;
            6'd34: mag = 7'd98;
            6'd35: mag = 7'd100;
            6'd36: mag = 7'd103;
            6'd37: mag = 7'd105;
            6'd38: mag = 7'd107;
            6'd39: mag = 7'd109;
            6'd40: mag = 7'd111;
            6'd41: mag = 7'd113;
            6'd42: mag = 7'd115;
            6'd43: mag = 7'd117;
            6'd44: mag = 7'd118;
            6'd45: mag = 7'd120;
            6'd46: mag = 7'd121;
            6'd47: mag = 7'd123;
            6'd48: mag = 7'd124;
            6'd49: mag = 7'd125;
            6'd50: mag = 7'd126;
            6'd51: mag = 7'd126;
            6'd52: mag = 7'd127;
            6'd53: mag = 7'd127;
            6'd54: mag = 7'd127;
            6'd55: mag = 7'd127;
            6'd56: mag = 7'd127;
            6'd57: mag = 7'd127;
            6'd58: mag = 7'd127;
            6'd59: mag = 7'd127;
            6'd60: mag = 7'd127;
            6'd61: mag = 7'd127;
            6'd62: mag = 7'd127;
            6'd63: mag = 7'd127;

            default: mag = 7'd0;

        endcase
    end

    // ========================================================
    // Stage 2
    // --------------------------------------------------------
    // Reconstruct signed waveform
    // Convert to unsigned representation
    //
    // Positive:
    //
    //   128 + magnitude
    //
    // Negative:
    //
    //   128 - magnitude
    //
    // ========================================================

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            // Midscale output
            result <= 8'd128;

        end else begin

            if (valid) begin

                // Negative half-wave
                if (negative)
                    result <= 8'd128 - {1'b0, mag};

                // Positive half-wave
                else
                    result <= 8'd128 + {1'b0, mag};

            end
        end
    end

endmodule
