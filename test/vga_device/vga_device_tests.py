
import cocotb
import utils
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_vga_device(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    dut.wb_cyc.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10);

    assert dut.vgaconfig_enabled.value == 0, "vgaconfig_enabled must be 0 after reset"

    await utils.wishbone_write32(dut, 0, 0x7FFFFFFF)

    assert dut.vgaconfig_enabled.value == 0
    assert int(dut.vgaconfig_addr.value) == 0x7FFFC000

    await utils.wishbone_write32(dut, 0, 0xFFFFFFFF)

    assert dut.vgaconfig_enabled.value == 1
    assert dut.vgaconfig_addr.value == 0x7FFFC000

    await utils.wishbone_write32(dut, 0, 0)

    assert dut.vgaconfig_enabled.value == 0
    assert dut.vgaconfig_addr.value == 0

    await utils.wishbone_write32(dut, 0, 0xDEADBEEF)

    assert dut.vgaconfig_enabled.value == 1
    assert dut.vgaconfig_addr.value == 0x5EAD8000
