# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


def phase_input(mode, phase7):
    return ((mode & 1) << 7) | (phase7 & 0x7F)


async def apply_and_check(dut, mode, phase7, expected_a, expected_b, name, tolerance=0):
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
        f"{name} output A failed: expected={expected_a} ± {tolerance}, got={actual_a}"
    )

    assert abs(actual_b - expected_b) <= tolerance, (
        f"{name} output B failed: expected={expected_b} ± {tolerance}, got={actual_b}"
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

    # Mode 0: sine / cosine
    await apply_and_check(dut, 0, 0,   128, 255, "sin/cos 0 deg")
    await apply_and_check(dut, 0, 32,  255, 128, "sin/cos 90 deg")
    await apply_and_check(dut, 0, 64,  128, 1,   "sin/cos 180 deg")
    await apply_and_check(dut, 0, 96,  1,   128, "sin/cos 270 deg")

    await apply_and_check(dut, 0, 11, 195, 240, "sin/cos approx 30 deg", tolerance=3)
    await apply_and_check(dut, 0, 16, 221, 221, "sin/cos 45 deg", tolerance=3)
    await apply_and_check(dut, 0, 21, 241, 195, "sin/cos approx 60 deg", tolerance=3)

    # Mode 1: tangent / cotangent
    await apply_and_check(dut, 1, 0,   128, 255, "tan/cot 0 deg")
    await apply_and_check(dut, 1, 16,  255, 252, "tan/cot 45 deg", tolerance=3)
    await apply_and_check(dut, 1, 32,  1,   128, "tan/cot 90 deg")
    await apply_and_check(dut, 1, 64,  128, 255, "tan/cot 180 deg")
    await apply_and_check(dut, 1, 48,  1,   1,   "tan/cot 135 deg",tolerance=3)