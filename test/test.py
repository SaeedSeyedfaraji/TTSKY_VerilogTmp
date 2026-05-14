# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


def input_word(mode, value):
    return ((mode & 0x3) << 6) | (value & 0x3F)


async def apply_and_check(dut, mode, value, expected_a, expected_b, name, tolerance=0):
    dut._log.info(
        f"Test {name}: mode={mode}, value={value}, "
        f"expected_a={expected_a}, expected_b={expected_b}, tolerance={tolerance}"
    )

    dut.ui_in.value = input_word(mode, value)
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
    dut._log.info("Start PolyTrig static + NCO test")

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

    # mode 00: static sine / cosine
    await apply_and_check(dut, 0, 0,  128, 255, "sin/cos 0 deg")
    await apply_and_check(dut, 0, 16, 255, 128, "sin/cos 90 deg")
    await apply_and_check(dut, 0, 32, 128, 1,   "sin/cos 180 deg")
    await apply_and_check(dut, 0, 48, 1,   128, "sin/cos 270 deg")
    await apply_and_check(dut, 0, 8,  221, 221, "sin/cos 45 deg", tolerance=3)

    # mode 01: static tangent / cotangent
    await apply_and_check(dut, 1, 0,  128, 255, "tan/cot 0 deg")
    await apply_and_check(dut, 1, 8,  255, 252, "tan/cot 45 deg", tolerance=3)
    await apply_and_check(dut, 1, 16, 1,   128, "tan/cot 90 deg")
    await apply_and_check(dut, 1, 24, 4,   4,   "tan/cot 135 deg", tolerance=3)

    # mode 10: NCO sine / cosine
    # value = 1 -> step = 4 phase counts per clock
    dut.rst_n.value = 0
    dut.ui_in.value = input_word(2, 1)
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 5)

    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # Around first quarter cycle: sine should be high, cosine should be reduced
    await ClockCycles(dut.clk, 16)
    await Timer(100, unit="ns")

    actual_sin = int(dut.uo_out.value)
    actual_cos = int(dut.uio_out.value)

    assert actual_sin > 200, (
        f"NCO rising sine failed: expected sine high, got {actual_sin}"
    )

    assert actual_cos < 200, (
        f"NCO falling cosine failed: expected cosine reduced, got {actual_cos}"
    )

    # Around second quarter cycle: sine should reduce, cosine should be low
    await ClockCycles(dut.clk, 16)
    await Timer(100, unit="ns")

    actual_sin = int(dut.uo_out.value)
    actual_cos = int(dut.uio_out.value)

    assert actual_sin < 200, (
        f"NCO falling sine failed: expected sine reduced, got {actual_sin}"
    )

    assert actual_cos < 80, (
        f"NCO negative cosine failed: expected cosine low, got {actual_cos}"
    )