import cocotb
import math
import random

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from utils import memory_device, wishbone_read8, wishbone_read16, wishbone_read32, wishbone_write8, wishbone_write16, wishbone_write32


@cocotb.test()
async def test_init(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1

    await ClockCycles(dut.clk, 10)

    dut.rst.value = 0

    await ClockCycles(dut.clk, 256)

