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


async def collect_nco_samples(dut, waveform, amp, cycles=80):
    dut.rst_n.value = 0
    dut.ui_in.value = input_word(2, 1)
    dut.uio_in.value = ((amp & 0x3) << 2) | (waveform & 0x3)

    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    samples_a = []
    samples_b = []

    for _ in range(cycles):
        await ClockCycles(dut.clk, 1)
        await Timer(1, unit="ns")
        samples_a.append(int(dut.uo_out.value))
        samples_b.append(int(dut.uio_out.value))

    dut._log.info(
        f"NCO waveform={waveform}, amp={amp}, "
        f"A samples={samples_a}, B samples={samples_b}"
    )

    return samples_a, samples_b


def check_dynamic_range(samples, name, min_range=80):
    s_min = min(samples)
    s_max = max(samples)

    assert s_max > s_min, f"{name} is stuck: samples={samples}"
    assert s_max - s_min >= min_range, (
        f"{name} dynamic range too small: min={s_min}, max={s_max}, samples={samples}"
    )


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start PolyTrig static + programmable NCO test")

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

    # mode 10: NCO sine/cosine, full amplitude
    sin_samples, cos_samples = await collect_nco_samples(
        dut, waveform=0, amp=0, cycles=80
    )

    assert max(sin_samples) > 200, "NCO sine did not reach high region"
    assert min(sin_samples) < 80,  "NCO sine did not reach low region"
    assert max(cos_samples) > 200, "NCO cosine did not reach high region"
    assert min(cos_samples) < 80,  "NCO cosine did not reach low region"

    check_dynamic_range(sin_samples, "NCO sine", min_range=120)
    check_dynamic_range(cos_samples, "NCO cosine", min_range=120)

    # waveform 01: triangle / saw
    tri_samples, saw_samples = await collect_nco_samples(
        dut, waveform=1, amp=0, cycles=80
    )

    check_dynamic_range(tri_samples, "NCO triangle", min_range=120)
    check_dynamic_range(saw_samples, "NCO saw", min_range=120)

    # waveform 10: square / quadrature square
    sq_a_samples, sq_b_samples = await collect_nco_samples(
        dut, waveform=2, amp=0, cycles=80
    )

    assert max(sq_a_samples) >= 240 and min(sq_a_samples) <= 20, (
        f"NCO square A failed: samples={sq_a_samples}"
    )

    assert max(sq_b_samples) >= 240 and min(sq_b_samples) <= 20, (
        f"NCO square B failed: samples={sq_b_samples}"
    )

    # waveform 11: rectified sine/cosine
    rect_a_samples, rect_b_samples = await collect_nco_samples(
        dut, waveform=3, amp=0, cycles=80
    )

    check_dynamic_range(rect_a_samples, "NCO rectified sine", min_range=100)
    check_dynamic_range(rect_b_samples, "NCO rectified cosine", min_range=100)

    # amplitude check: same sine/cos NCO but reduced amplitude
    full_amp_samples, _ = await collect_nco_samples(
        dut, waveform=0, amp=0, cycles=80
    )

    half_amp_samples, _ = await collect_nco_samples(
        dut, waveform=0, amp=2, cycles=80
    )

    full_range = max(full_amp_samples) - min(full_amp_samples)
    half_range = max(half_amp_samples) - min(half_amp_samples)

    dut._log.info(
        f"Amplitude check: full_range={full_range}, half_range={half_range}"
    )

    assert half_range < full_range, (
        f"Amplitude scaling failed: full_range={full_range}, half_range={half_range}"
    )

    assert half_range > 40, (
        f"Half amplitude range too small: half_range={half_range}"
    )

    dut._log.info("PolyTrig static + programmable NCO test completed successfully")