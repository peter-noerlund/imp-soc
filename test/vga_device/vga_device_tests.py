
import cocotb
import utils
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_wishbone_interface(dut):
    clock = Clock(dut.clk, 19.860, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    dut.wb_cyc.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10);

    assert dut.vgaconfig_enabled.value == 0, "VGA is disabled after reset"

    val = await utils.wishbone_read32(dut, 0)

    assert val == 0

    await utils.wishbone_write32(dut, 4, 0xFFFFFFFF)

    assert dut.vgaconfig_enabled.value == 0
    assert int(dut.vgaconfig_adr.value) == 0xFFFFFFFC

    val = await utils.wishbone_read32(dut, 0)
    assert val == 0

    val = await utils.wishbone_read32(dut, 4)
    assert val == 0xFFFFFFFC

    await utils.wishbone_write32(dut, 0, 1)

    assert dut.vgaconfig_enabled.value == 1
    assert dut.vgaconfig_adr.value == 0xFFFFFFFC

    val = await utils.wishbone_read32(dut, 0)
    assert val == 1

    val = await utils.wishbone_read32(dut, 4)
    assert val == 0xFFFFFFFC

    await utils.wishbone_write32(dut, 0, 0)

    assert dut.vgaconfig_enabled.value == 0
    assert dut.vgaconfig_adr.value == 0xFFFFFFFC

    await utils.wishbone_write32(dut, 4, 0xDEADBEEF)

    assert dut.vgaconfig_enabled.value == 0
    assert dut.vgaconfig_adr.value == 0xDEADBEEC

    val = await utils.wishbone_read32(dut, 0)
    assert val == 0

    val = await utils.wishbone_read32(dut, 4)
    assert val == 0xDEADBEEC
