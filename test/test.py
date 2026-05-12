# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


async def apply_and_check(dut, phase, mode, expected, name, tolerance=0):
    """
    Apply one sine/cosine transaction and check result.

    Interface:
      ui_in      = phase
      uio_in[0] = start
      uio_in[1] = mode
                  0 = sine
                  1 = cosine

      uo_out     = result
      uio_out[0] = valid/done
    """

    dut._log.info(
        f"Test {name}: phase={phase}, mode={mode}, "
        f"expected={expected}, tolerance={tolerance}"
    )

    dut.ui_in.value = phase
    dut.uio_in.value = (mode << 1) | 1  # start=1

    await ClockCycles(dut.clk, 5)
    await Timer(500, unit="ns")

    actual = int(dut.uo_out.value)

    assert abs(actual - expected) <= tolerance, (
        f"{name} failed: phase={phase}, mode={mode}, "
        f"expected={expected} ± {tolerance}, got={actual}"
    )

    assert (int(dut.uio_out.value) & 1) == 1

    # Deassert start
    dut.uio_in.value = 0

    await ClockCycles(dut.clk, 5)
    await Timer(500, unit="ns")

    assert (int(dut.uio_out.value) & 1) == 0


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start PolyTrig interpolated sine/cosine LUT test")

    # 100 MHz clock
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 5)
    await Timer(500, unit="ns")

    # -------------------------------------------------
    # Sine key points
    # phase 0   ->   0° -> sin = 0   -> output 128
    # phase 64  ->  90° -> sin = +1  -> output 255
    # phase 128 -> 180° -> sin = 0   -> output 128
    # phase 192 -> 270° -> sin = -1  -> output 1
    # -------------------------------------------------

    await apply_and_check(dut, phase=0,   mode=0, expected=128, name="sin 0 deg")
    await apply_and_check(dut, phase=64,  mode=0, expected=255, name="sin 90 deg")
    await apply_and_check(dut, phase=128, mode=0, expected=128, name="sin 180 deg")
    await apply_and_check(dut, phase=192, mode=0, expected=1,   name="sin 270 deg")

    # -------------------------------------------------
    # Sine non-trivial interpolation points
    #
    # phase 21 ≈ 30°
    # phase 32 = 45°
    # phase 43 ≈ 60°
    #
    # Expected values use unsigned sine mapping:
    #
    #   output = 128 + round(127 * sin(angle))
    # -------------------------------------------------

    await apply_and_check(dut, phase=21, mode=0, expected=191, name="sin approx 30 deg", tolerance=3)
    await apply_and_check(dut, phase=32, mode=0, expected=218, name="sin 45 deg",        tolerance=3)
    await apply_and_check(dut, phase=43, mode=0, expected=238, name="sin approx 60 deg", tolerance=3)

    # -------------------------------------------------
    # Cosine key points
    # cos(x) = sin(x + 90°)
    #
    # phase 0   ->   0° -> cos = +1  -> output 255
    # phase 64  ->  90° -> cos = 0   -> output 128
    # phase 128 -> 180° -> cos = -1  -> output 1
    # phase 192 -> 270° -> cos = 0   -> output 128
    # -------------------------------------------------

    await apply_and_check(dut, phase=0,   mode=1, expected=255, name="cos 0 deg")
    await apply_and_check(dut, phase=64,  mode=1, expected=128, name="cos 90 deg")
    await apply_and_check(dut, phase=128, mode=1, expected=1,   name="cos 180 deg")
    await apply_and_check(dut, phase=192, mode=1, expected=128, name="cos 270 deg")

    # -------------------------------------------------
    # Cosine non-trivial interpolation points
    # -------------------------------------------------

    await apply_and_check(dut, phase=21, mode=1, expected=238, name="cos approx 30 deg", tolerance=3)
    await apply_and_check(dut, phase=32, mode=1, expected=218, name="cos 45 deg",        tolerance=3)
    await apply_and_check(dut, phase=43, mode=1, expected=191, name="cos approx 60 deg", tolerance=3)