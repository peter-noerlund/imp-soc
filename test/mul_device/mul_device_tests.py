import cocotb
import random
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from utils import wishbone_read32, wishbone_write32


async def test_multiply(dut, a, b):
    expected_res = a * b

    await wishbone_write32(dut, 0x20, a)
    await wishbone_write32(dut, 0x24, b)
    lo = await wishbone_read32(dut, 0x20)
    hi = await wishbone_read32(dut, 0x24)

    res = (hi << 32) | lo
    if res & (1 << 63):
        res -= 1 << 64
    assert res == expected_res


@cocotb.test()
async def test_mul_device(dut):
    clock = Clock(dut.clk, 19.860, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    dut.wb_cyc.value = 0
    dut.wb_stb.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    await ClockCycles(dut.clk, 10)

    await test_multiply(dut, 0, 0)

    for i in range(31):
        a = 1 << i
        neg_a = 0 - a
        await test_multiply(dut, a, 0)
        await test_multiply(dut, 0, a)
        await test_multiply(dut, neg_a, 0)
        await test_multiply(dut, 0, neg_a)

    for i in range(31):
        a = 1 << i
        neg_a = 0 - a
        for j in range(31):
            b = 1 << i
            neg_b = 0 - b

            await test_multiply(dut, a, b)
            await test_multiply(dut, neg_a, b)
            await test_multiply(dut, a, neg_b)
            await test_multiply(dut, neg_a, neg_b)
        

    for i in range(1024):
        a = random.randint(-2147483648, 2147483647)
        b = random.randint(0, 2147483647)
        await test_multiply(dut, a, b)