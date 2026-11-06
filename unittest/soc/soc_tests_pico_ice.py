import cocotb
import utils

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


#@cocotb.test()
async def test_soc_vga(dut):
    clock = Clock(dut.clk, 39.880, unit="ns")
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
    
    # Wait for hsync to finish
    for i in range(96):
        assert dut.vga_hsync.value == 0, f"Horizontal sync is low at hsync cycle {i}"
        assert dut.vga_vsync.value == 1, f"Vertical sync is low at hsync cycle {i}"
        assert int(dut.vga_red.value) == 0, f"Red is desaturated at hsync cycle {i}"
        assert int(dut.vga_green.value) == 0, f"Green is desaturated at hsync cycle {i}"
        assert int(dut.vga_blue.value) == 0, f"Blue is desaturated at hsync cycle {i}"
        await ClockCycles(dut.clk, 1)

    # Wait for back porch
    for i in range(40):
        assert dut.vga_hsync.value == 1, f"Horizontal sync is high at back porch cycle {i}"
        assert dut.vga_vsync.value == 1, f"Vertical sync is high at back porch cycle {i}"
        assert int(dut.vga_red.value) == 0, f"Red is desaturated at back porch cycle {i}"
        assert int(dut.vga_green.value) == 0, f"Green is desaturated at back porch cycle {i}"
        assert int(dut.vga_blue.value) == 0, f"Blue is desaturated at back porch cycle {i}"
        await ClockCycles(dut.clk, 1)

    # Wait for left border
    for i in range(8):
        assert dut.vga_hsync.value == 1
        assert dut.vga_vsync.value == 1
        assert int(dut.vga_red.value) == 0
        assert int(dut.vga_green.value) == 0
        assert int(dut.vga_blue.value) == 0
        await ClockCycles(dut.clk, 1)

    # Wait for additional border
    for i in range(64):
        assert dut.vga_hsync.value == 1
        assert dut.vga_vsync.value == 1
        assert int(dut.vga_red.value) == 0
        assert int(dut.vga_green.value) == 0
        assert int(dut.vga_blue.value) == 0
        await ClockCycles(dut.clk, 1)

    # Verify that all pixels are red
    for i in range(512):
        assert dut.vga_hsync.value == 1, f"HSync is high at pixel {i}"
        assert dut.vga_vsync.value == 1, f"VSync is high at pixel {i}"
        assert int(dut.vga_red.value) == 3, f"Red is saturated at pixel {i}"
        assert int(dut.vga_green.value) == 0, f"Green is desaturated at pixel {i}"
        assert int(dut.vga_blue.value) == 0, f"Blue is desaturated at pixel {i}"
        await ClockCycles(dut.clk, 1)


async def verify_pixel(dut, hpos: int, vpos: int, hsync: bool, vsync: bool, blank: bool, pixel_info: str):
    assert dut.vga_hsync.value == (0 if hsync else 1), f"Invalid hsync at {pixel_info}"
    assert dut.vga_vsync.value == (0 if vsync else 1), f"Invalid vsync at {pixel_info}"
    assert dut.vga_blank.value == (1 if blank else 0), f"Invalid blank ({blank}) at {pixel_info}"
    assert int(dut.vga_hpos.value) == hpos, f"Invalid horizontal pos at {pixel_info}"
    assert int(dut.vga_vpos.value) == vpos, f"Invalid vertical pos at {pixel_info}"
    await ClockCycles(dut.clk, 1)


async def verify_line(dut, vpos: int, vsync: bool, blank: bool, line_info: str):
    # Horizontal sync
    for i in range(96):
        await verify_pixel(dut, 512 + 64 + 8 + 8 + i, vpos, True, vsync, True, f"{line_info}, horizontal sync pixel {i}")

    # Horizontal back porch
    for i in range(40):
        await verify_pixel(dut, 512 + 64 + 8 + 8 + 96 + i, vpos, False, vsync, True, f"{line_info}, horizontal back porch pixel {i}")
    
    # Horizontal left border
    for i in range(8):
        await verify_pixel(dut, 512 + 64 + 8 + 8 + 96 + 40 + i, vpos, False, vsync, True, f"{line_info}, left border pixel {i}")
    
    # Horizontal left letter box
    for i in range(64):
        await verify_pixel(dut, 512 + 64 + 8 + 8 + 96 + 40 + 8 + i, vpos, False, vsync, True, f"{line_info}, left letter box pixel {i}")
    
    # Horizontal pixels
    for i in range(512):
        await verify_pixel(dut, i, vpos, False, vsync, blank, f"{line_info}, visible pixel {i}")

    # Horizontal right letter box
    for i in range(64):
        await verify_pixel(dut, 512 + i, vpos, False, vsync, True, f"{line_info}, right letter box pixel {i}")
        
    # Horizontal right border
    for i in range(8):
        await verify_pixel(dut, 512 + 64 + i, vpos, False, vsync, True, f"{line_info}, right border pixel {i}")
        
    # Horizontal front porch
    for i in range(8):
        await verify_pixel(dut, 512 + 64 + 8 + i, vpos, False, vsync, True, f"{line_info}, horizontal front porch pixel {i}")


async def verify_frame(dut, frame_info: str):
    # Vertical sync
    for i in range(2):
        await verify_line(dut, 384 + 48 + 8 + 2 + i, True, True, f"{frame_info}, vertical sync line {i}")

    # Vertical back porch
    for i in range(25):
        await verify_line(dut, 384 + 48 + 8 + 2 + 2 + i, False, True, f"{frame_info}, vertical back porch line {i}")

    # Vertical top border
    for i in range(8):
        await verify_line(dut, 384 + 48 + 8 + 2 + 2 + 25 + i, False, True, f"{frame_info}, top border line {i}")

    # Vertical top letter box
    for i in range(48):
        await verify_line(dut, 384 + 48 + 8 + 2 + 2 + 25 + 8 + i, False, True, f"{frame_info}, top letter box line {i}")

    # Vertical pixels
    for i in range(384):
        await verify_line(dut, i, False, False, f"{frame_info}, vertical visible line {i}")

    # Vertical bottom letter box
    for i in range(48):
        await verify_line(dut, 384 + i, False, True, f"{frame_info}, bottom letter box line {i}")

    # Vertical bottom border
    for i in range(8):
        await verify_line(dut, 384 + 48 + i, False, True, f"{frame_info}, bottom border line {i}")

    # Vertical front porch
    for i in range(2):
        await verify_line(dut, 384 + 48 + 8 + i, False, True, f"{frame_info}, vertical front porch line {i}")


@cocotb.test()
async def test_soc_vga_timing(dut):
    clock = Clock(dut.clk, 39.880, unit="ns")
    cocotb.start_soon(clock.start())

    flash = bytearray(16 * 1024 * 1024)
    code = [
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

    # Wait for sync
    for i in range(800 * 525):
        if dut.vga_vsync.value == 0 and dut.vga_hsync.value == 0:
            break
        await ClockCycles(dut.clk, 1)

    assert dut.vga_vsync.value == 0 and dut.vga_hsync.value == 0, "Combined vsync/hsync happens"

    for i in range(3):
        await verify_frame(dut.vga_renderer.timing, f"frame {i}")
