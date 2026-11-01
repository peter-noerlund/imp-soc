import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from utils import wishbone_read32


@cocotb.test()
async def test_clock_device(dut):
    clock = Clock(dut.clk, 19.860, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    dut.wb_cyc.value = 0
    dut.wb_stb.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    await ClockCycles(dut.clk, 10)

    last_value = 0
    for i in range(1000):
        value = await wishbone_read32(dut, 0)
        assert value > last_value
        last_value = value