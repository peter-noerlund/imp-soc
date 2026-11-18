import cocotb
import utils

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


@cocotb.test()
async def test_soc_vga(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    flash = bytearray(16 * 1024 * 1024)
    code = [
        utils.lui(utils.A3, 0x00305),
        utils.lui(utils.A4, 0x01002),
        utils.addi(utils.A3, utils.A3, 0x555),
        utils.addi(utils.A4, utils.A4, -2048),
        utils.lui(utils.A5, 0x1000),
        utils.sw(utils.A5, utils.A3, 0),
        utils.addi(utils.A5, utils.A5, 4),
        utils.bne(utils.A5, utils.A4, -8),
        utils.lui(utils.A5, 0x02000),
        utils.lui(utils.A4, 0x81000),
        utils.sw(utils.A5, utils.A4, 12),
        utils.jal(utils.ZERO, 0)
    ]
    for i in range(len(code)):
        instr = code[i]
        flash[i * 4] = instr & 0xFF
        flash[i * 4 + 1] = (instr >> 8) & 0xFF
        flash[i * 4 + 2] = (instr >> 16) & 0xFF
        flash[i * 4 + 3] = (instr >> 24) & 0xFF
    cocotb.start_soon(utils.memory_device(dut, dut.spi_flash_ss_n, flash))
    
    psram = bytearray(8 * 1024 * 1024)
    cocotb.start_soon(utils.memory_device(dut, dut.spi_psram_ss_n, psram))

    dut.rst.value = 1

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    # Wait for code to execute
    await ClockCycles(dut.clk, 786432)

    # Wait for hsync
    for i in range(2048):
        if dut.vga_hsync.value == 0:
            break
        await ClockCycles(dut.clk, 1)
    
    assert dut.vga_hsync.value == 0, "VGA Hsync happens"

    # Wait for hsync to finish
    for i in range(136):
        assert dut.vga_hsync.value == 0
        await ClockCycles(dut.clk, 1)

    # Wait for back porch
    for i in range(160):
        assert dut.vga_hsync.value == 1
        await ClockCycles(dut.clk, 1)

    # Verify that all pixels are red
    for i in range(1024):
        assert int(dut.vga_red.value) == 3
        assert int(dut.vga_green.value) == 0
        assert int(dut.vga_blue.value) == 0
        await ClockCycles(dut.clk, 1)



