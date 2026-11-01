
import cocotb
import utils
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_wishbone_interface(dut):
    VGA_CTRL = 0
    VGA_ADDR = 4

    clock = Clock(dut.clk, 19.860, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    dut.wb_cyc.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10);

    assert dut.vgaconfig_enabled.value == 0, "vgaconfig_enabled must be 0 after reset"

    # Verify that reading VGA_CTRL reflects that
    val = await utils.wishbone_read8(dut, VGA_CTRL)
    assert val & 0x01 == 0, "Enable bit must be 0 when reading 8-bit value"

    val = await utils.wishbone_read16(dut, VGA_CTRL)
    assert val & 0x0001 == 0, "Enable bit must be 0 when reading 16-bit value"

    val = await utils.wishbone_read32(dut, VGA_CTRL)
    assert val & 0x00000001 == 0, "Enable bit must be 0 when reading 32-bit value"

    for scale in range(8):
        await utils.wishbone_write8(dut, VGA_CTRL + 1, scale)
        assert dut.vgaconfig_enabled.value == 0, f"Writing scale {i} in 8-bit should not affect enabled flag"
        assert int(dut.vgaconfig_scale.value) == scale, f"Writing scale {i} in 8-bit should be visible on vgaconfig_scale"
        
        val = await utils.wishbone_read8(dut, VGA_CTRL + 1)
        assert val == scale, f"Writing scale {i} in 8-bit, should read out correctly in 8-bit"
        
        val = await utils.wishbone_read16(dut, VGA_CTRL)
        assert val & 0xFF00 == scale << 8, f"Writing scale {i} in 8-bit, should read out correctly in 8-bit"
        
        val = await utils.wishbone_read32(dut, VGA_CTRL)
        assert val & 0xFF00 == scale << 8, f"Writing scale {i} in 8-bit, should read out correctly in 8-bit"

    for scale in range(8):
        await utils.wishbone_write16(dut, VGA_CTRL, scale << 8)
        assert dut.vgaconfig_enabled.value == 0, f"Writing scale {i} in 16-bit should affect enabled flag correctly"
        assert int(dut.vgaconfig_scale.value) == scale, f"Writing scale {i} in 16-bit should be visible on vgaconfig_scale"
        
        val = await utils.wishbone_read8(dut, VGA_CTRL + 1)
        assert val == scale, f"Writing scale {i} in 16-bit, should read out correctly in 8-bit"
        
        val = await utils.wishbone_read16(dut, VGA_CTRL)
        assert val & 0xFF00 == scale << 8, f"Writing scale {i} in 16-bit, should read out correctly in 8-bit"
        
        val = await utils.wishbone_read32(dut, VGA_CTRL)
        assert val & 0xFF00 == scale << 8, f"Writing scale {i} in 16-bit, should read out correctly in 8-bit"

    for scale in range(8):
        await utils.wishbone_write32(dut, VGA_CTRL, scale << 8)
        assert dut.vgaconfig_enabled.value == 0, f"Writing scale {i} in 32-bit should affect enabled flag correctly"
        assert int(dut.vgaconfig_scale.value) == scale, f"Writing scale {i} in 32-bit should be visible on vgaconfig_scale"
        
        val = await utils.wishbone_read8(dut, VGA_CTRL + 1)
        assert val == scale, f"Writing scale {i} in 32-bit, should read out correctly in 8-bit"
        
        val = await utils.wishbone_read16(dut, VGA_CTRL)
        assert val & 0xFF00 == scale << 8, f"Writing scale {i} in 32-bit, should read out correctly in 8-bit"
        
        val = await utils.wishbone_read32(dut, VGA_CTRL)
        assert val & 0xFF00 == scale << 8, f"Writing scale {i} in 32-bit, should read out correctly in 8-bit"

    await utils.wishbone_write8(dut, VGA_CTRL + 1, 2)
    await utils.wishbone_write32(dut, VGA_ADDR, 0xFFFFFFFF)

    assert dut.vgaconfig_enabled.value == 0
    assert dut.vgaconfig_scale.value == 2
    assert int(dut.vgaconfig_addr.value) == 0xFFFFC000

    val = await utils.wishbone_read32(dut, VGA_ADDR)
    assert val == 0xFFFFC000

    await utils.wishbone_write8(dut, VGA_CTRL, 1)

    assert dut.vgaconfig_enabled.value == 1
    assert dut.vgaconfig_scale.value == 2
    assert dut.vgaconfig_addr.value == 0xFFFFC000

    val = await utils.wishbone_read32(dut, VGA_CTRL)
    assert val == 0x0201

    val = await utils.wishbone_read32(dut, VGA_ADDR)
    assert val == 0xFFFFC000

    await utils.wishbone_write8(dut, VGA_CTRL, 0)

    assert dut.vgaconfig_enabled.value == 0
    assert dut.vgaconfig_scale.value == 2
    assert dut.vgaconfig_addr.value == 0xFFFFC000

    await utils.wishbone_write32(dut, VGA_ADDR, 0xDEADBEEF)

    assert dut.vgaconfig_enabled.value == 0
    assert dut.vgaconfig_scale.value == 2
    assert dut.vgaconfig_addr.value == 0xDEAD8000

    val = await utils.wishbone_read32(dut, VGA_ADDR)
    assert val == 0xDEAD8000
