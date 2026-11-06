
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def verify_pixel(dut, hpos: int, vpos: int, hsync: bool, vsync: bool, blank: bool, pixel_info: str):
    assert dut.vga_hsync.value == (0 if hsync else 1), f"Invalid hsync at {pixel_info}"
    assert dut.vga_vsync.value == (0 if vsync else 1), f"Invalid vsync at {pixel_info}"
    assert dut.vga_blank.value == (1 if blank else 0), f"Invalid blank ({blank}) at {pixel_info}"
    assert int(dut.vga_hpos.value) == hpos, f"Invalid horizontal pos at {pixel_info}"
    assert int(dut.vga_vpos.value) == vpos, f"Invalid vertical pos at {pixel_info}"
    await ClockCycles(dut.clk, 1)


async def verify_line(dut, vpos: int, vsync: bool, blank: bool, line_info: str):
    # Horizontal sync
    for i in range(136):
        await verify_pixel(dut, 1048 + i, vpos, True, vsync, True, f"{line_info}, horizontal sync pixel {i}")

    # Horizontal back porch
    for i in range(160):
        await verify_pixel(dut, 1048 + 136 + i, vpos, False, vsync, True, f"{line_info}, horizontal back porch pixel {i}")
    
    # Horizontal pixels
    for i in range(1024):
        await verify_pixel(dut, i, vpos, False, vsync, blank, f"{line_info}, horizontal visible pixel {i}")
    
    # Horizontal front porch
    for i in range(24):
        await verify_pixel(dut, 1024 + i, vpos, False, vsync, True, f"{line_info}, horizontal pixel {i}")


async def verify_frame(dut, frame_info: str):
    # Vertical sync
    for i in range(6):
        await verify_line(dut, 771 + i, True, True, f"{frame_info}, vertical sync line {i}")

    # Vertical back porch
    for i in range(29):
        await verify_line(dut, 771 + 6 + i, False, True, f"{frame_info}, vertical back porch line {i}")

    # Vertical pixels
    for i in range(768):
        await verify_line(dut, i, False, False, f"{frame_info}, vertical visible line {i}")

    # Vertical front porch
    for i in range(3):
        await verify_line(dut, 768 + i, False, True, f"{frame_info}, vertical front porch line {i}")


@cocotb.test()
async def test_vga_timing(dut):
    clock = Clock(dut.clk, 15, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    # Wait for sync
    for i in range(1344 * 806):
        if dut.vga_vsync.value == 0 and dut.vga_hsync.value == 0:
            break
        await ClockCycles(dut.clk, 1)

    assert dut.vga_vsync.value == 0 and dut.vga_hsync.value == 0, "Combined vsync/hsync"

    for i in range(3):
        await verify_frame(dut, f"frame {i}")

    
