import cocotb
import utils
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_clock_device(dut):
    dut.wb_cyc.value = 0
    dut.wb_stb.value = 0

    await utils.init(dut)

    last_value = 0
    for i in range(1000):
        value = await utils.wishbone_read32(dut, 0)
        assert value > last_value
        last_value = value