
import cocotb
import utils
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_wishbone_interface(dut):
    clock = Clock(dut.clk, 19.860, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10);

    assert dut.fb_enabled.value == 0

    for i in range(31):
        await utils.wishbone_write32(dut, 0, 1 << i)
        assert dut.fb_enabled.value == 0
        assert int(dut.fb_addr.value) == (1 << i) & 0x00FFFFC0

    for i in range(31):
        await utils.wishbone_write32(dut, 0, 0x80000000 | (1 << i))
        assert dut.fb_enabled.value == 1
        assert int(dut.fb_addr.value) == (1 << i) & 0x00FFFFC0