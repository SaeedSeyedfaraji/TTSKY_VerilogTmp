# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


async def apply_and_check(dut, phase, expected_sin, expected_cos, name, tolerance=0):
    """
    Interface:
      ui_in[7:0]   = phase
      uo_out[7:0]  = sine output
      uio_out[7:0] = cosine output
    """

    dut._log.info(
        f"Test {name}: phase={phase}, "
        f"expected_sin={expected_sin}, expected_cos={expected_cos}, "
        f"tolerance={tolerance}"
    )

    dut.ui_in.value = phase
    dut.uio_in.value = 0

    await ClockCycles(dut.clk, 2)
    await Timer(100, unit="ns")

    actual_sin = int(dut.uo_out.value)
    actual_cos = int(dut.uio_out.value)

    assert abs(actual_sin - expected_sin) <= tolerance, (
        f"{name} sine failed: phase={phase}, "
        f"expected={expected_sin} ± {tolerance}, got={actual_sin}"
    )

    assert abs(actual_cos - expected_cos) <= tolerance, (
        f"{name} cosine failed: phase={phase}, "
        f"expected={expected_cos} ± {tolerance}, got={actual_cos}"
    )


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start PolyTrig simultaneous sine/cosine LUT test")

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

    await apply_and_check(
        dut,
        phase=0,
        expected_sin=128,
        expected_cos=255,
        name="0 deg"
    )

    await apply_and_check(
        dut,
        phase=64,
        expected_sin=255,
        expected_cos=128,
        name="90 deg"
    )

    await apply_and_check(
        dut,
        phase=128,
        expected_sin=128,
        expected_cos=1,
        name="180 deg"
    )

    await apply_and_check(
        dut,
        phase=192,
        expected_sin=1,
        expected_cos=128,
        name="270 deg"
    )

    await apply_and_check(
        dut,
        phase=21,
        expected_sin=192,
        expected_cos=241,
        name="approx 30 deg",
        tolerance=3
    )

    await apply_and_check(
        dut,
        phase=32,
        expected_sin=221,
        expected_cos=221,
        name="45 deg",
        tolerance=3
    )

    await apply_and_check(
        dut,
        phase=43,
        expected_sin=243,
        expected_cos=192,
        name="approx 60 deg",
        tolerance=3
    )