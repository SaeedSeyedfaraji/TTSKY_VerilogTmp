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
    # value = 1 means slow NCO stepping.
    # Do not check one exact sample point; check waveform behavior over time.
    dut._log.info("Start NCO dynamic behavior test")

    dut.rst_n.value = 0
    dut.ui_in.value = input_word(2, 1)
    dut.uio_in.value = 0

    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    sin_samples = []
    cos_samples = []

    for _ in range(80):
        await ClockCycles(dut.clk, 1)
        await Timer(1, unit="ns")
        sin_samples.append(int(dut.uo_out.value))
        cos_samples.append(int(dut.uio_out.value))

    dut._log.info(f"NCO sine samples: {sin_samples}")
    dut._log.info(f"NCO cosine samples: {cos_samples}")

    sin_min = min(sin_samples)
    sin_max = max(sin_samples)
    cos_min = min(cos_samples)
    cos_max = max(cos_samples)

    dut._log.info(
        f"NCO ranges: sin_min={sin_min}, sin_max={sin_max}, "
        f"cos_min={cos_min}, cos_max={cos_max}"
    )

    # Basic waveform sanity checks
    assert sin_max > 200, (
        f"NCO sine never reached high region: max={sin_max}, samples={sin_samples}"
    )

    assert sin_min < 80, (
        f"NCO sine never reached low region: min={sin_min}, samples={sin_samples}"
    )

    assert cos_max > 200, (
        f"NCO cosine never reached high region: max={cos_max}, samples={cos_samples}"
    )

    assert cos_min < 80, (
        f"NCO cosine never reached low region: min={cos_min}, samples={cos_samples}"
    )

    # Check that signal is actually changing, not stuck
    assert sin_max - sin_min > 100, (
        f"NCO sine dynamic range too small: min={sin_min}, max={sin_max}"
    )

    assert cos_max - cos_min > 100, (
        f"NCO cosine dynamic range too small: min={cos_min}, max={cos_max}"
    )

    dut._log.info("PolyTrig static + NCO test completed successfully")