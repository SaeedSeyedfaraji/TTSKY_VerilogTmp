# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


def phase_input(mode, phase7):
    return ((mode & 1) << 7) | (phase7 & 0x7F)


async def apply_and_check(dut, mode, phase7, expected_a, expected_b, name, tolerance=0):
    """
    Interface:
      ui_in[7]   = mode
                   0 = sine/cosine
                   1 = tangent/cotangent

      ui_in[6:0] = phase angle

      uo_out     = function A
      uio_out    = function B

    Mode 0:
      uo_out  = sine
      uio_out = cosine

    Mode 1:
      uo_out  = tangent
      uio_out = cotangent
    """

    dut._log.info(
        f"Test {name}: mode={mode}, phase7={phase7}, "
        f"expected_a={expected_a}, expected_b={expected_b}, "
        f"tolerance={tolerance}"
    )

    dut.ui_in.value = phase_input(mode, phase7)
    dut.uio_in.value = 0

    await ClockCycles(dut.clk, 2)
    await Timer(100, unit="ns")

    actual_a = int(dut.uo_out.value)
    actual_b = int(dut.uio_out.value)

    assert abs(actual_a - expected_a) <= tolerance, (
        f"{name} output A failed: mode={mode}, phase7={phase7}, "
        f"expected={expected_a} ± {tolerance}, got={actual_a}"
    )

    assert abs(actual_b - expected_b) <= tolerance, (
        f"{name} output B failed: mode={mode}, phase7={phase7}, "
        f"expected={expected_b} ± {tolerance}, got={actual_b}"
    )


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start PolyTrig sin/cos and tan/cot LUT test")

    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 5)
    await Timer(100, unit="ns")

    # =========================================================
    # Mode 0: sine / cosine
    # phase7 values:
    #   0  ->   0 deg
    #   32 ->  90 deg
    #   64 -> 180 deg
    #   96 -> 270 deg
    # =========================================================

    await apply_and_check(
        dut,
        mode=0,
        phase7=0,
        expected_a=128,
        expected_b=255,
        name="sin/cos 0 deg"
    )

    await apply_and_check(
        dut,
        mode=0,
        phase7=32,
        expected_a=255,
        expected_b=128,
        name="sin/cos 90 deg"
    )

    await apply_and_check(
        dut,
        mode=0,
        phase7=64,
        expected_a=128,
        expected_b=1,
        name="sin/cos 180 deg"
    )

    await apply_and_check(
        dut,
        mode=0,
        phase7=96,
        expected_a=1,
        expected_b=128,
        name="sin/cos 270 deg"
    )

    await apply_and_check(
        dut,
        mode=0,
        phase7=11,
        expected_a=195,
        expected_b=240,
        name="sin/cos approx 30 deg",
        tolerance=3
    )

    await apply_and_check(
        dut,
        mode=0,
        phase7=16,
        expected_a=221,
        expected_b=221,
        name="sin/cos 45 deg",
        tolerance=3
    )

    await apply_and_check(
        dut,
        mode=0,
        phase7=21,
        expected_a=241,
        expected_b=195,
        name="sin/cos approx 60 deg",
        tolerance=3
    )

    # =========================================================
    # Mode 1: tangent / cotangent
    #
    # Saturated output format:
    #   128 = zero
    #   255 = positive saturation
    #   1   = negative saturation
    # =========================================================

    await apply_and_check(
        dut,
        mode=1,
        phase7=0,
        expected_a=128,
        expected_b=255,
        name="tan/cot 0 deg"
    )

    await apply_and_check(
        dut,
        mode=1,
        phase7=16,
        expected_a=255,
        expected_b=255,
        name="tan/cot 45 deg"
    )

    await apply_and_check(
        dut,
        mode=1,
        phase7=32,
        expected_a=1,
        expected_b=128,
        name="tan/cot 90 deg"
    )

    await apply_and_check(
        dut,
        mode=1,
        phase7=64,
        expected_a=128,
        expected_b=255,
        name="tan/cot 180 deg"
    )

    await apply_and_check(
        dut,
        mode=1,
        phase7=48,
        expected_a=1,
        expected_b=1,
        name="tan/cot 135 deg"
    )