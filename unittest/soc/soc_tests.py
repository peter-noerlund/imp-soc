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
        utils.lui(utils.X5, 0x01000),                   # X5 = 0x01000000
        utils.addi(utils.X6, utils.X5, 0),              # X6 = X5
        utils.lui(utils.X7, 0x44440),                   # X7 = 0x44440000
        utils.addi(utils.X7, utils.X7, 0x030),          # X7 += 0x030 ; X7 = 0x44440030
        utils.lui(utils.X8, 0x00002),                   # X8 = 0x00001000
        utils.addi(utils.X8, utils.X8, -2048),          # X8 += 0x800
        utils.add(utils.X8, utils.X8, utils.X5),        # X8 += X5
        utils.sw(utils.X6, utils.X7, 0),                # [T1] = T2
        utils.addi(utils.X6, utils.X6, 4),              # T1 += 4
        utils.bne(utils.X6, utils.X8, -8),              # if (T1 != T0) goto $-8
        utils.lui(utils.X9, 0x02000),
        utils.sw(utils.X9, utils.X5, 12),
        utils.addi(utils.X10, utils.ZERO, 1),
        utils.sw(utils.X9, utils.X10, 8),
        utils.jal(utils.ZERO, 0)                        # j $+0
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



