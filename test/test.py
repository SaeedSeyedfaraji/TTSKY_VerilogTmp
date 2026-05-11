# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start PolyTrig interface test")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    # Test sin placeholder: mode=0, start=1
    dut._log.info("Test sin placeholder")
    dut.ui_in.value = 25
    dut.uio_in.value = 0b00000001
    await ClockCycles(dut.clk, 1)
    await Timer(1, unit="ns")
    assert dut.uo_out.value == 25
    assert int(dut.uio_out.value) & 1 == 1

    # Deassert start
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)
    await Timer(1, unit="ns")
    assert int(dut.uio_out.value) & 1 == 0

    # Test cos placeholder: mode=1, start=1
    dut._log.info("Test cos placeholder")
    dut.ui_in.value = 40
    dut.uio_in.value = 0b00000011
    await ClockCycles(dut.clk, 1)
    await Timer(1, unit="ns")
    assert dut.uo_out.value == 127
    assert int(dut.uio_out.value) & 1 == 1

    # Deassert start
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 1)
    await Timer(1, unit="ns")
    assert int(dut.uio_out.value) & 1 == 0