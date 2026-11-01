
import cocotb
import utils
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def verify_line(dut, vsync: int, vporch: bool, line_info: str):
    # Horizontal sync
    for i in range(96):
        for j in range(2):
            assert dut.vga_hsync.value == 0, f"Invalid hsync at horizontal sync pixel {i}, cycle {j} {line_info}"
            assert int(dut.vga_vsync.value) == vsync, f"Invalid vsync at horizontal sync pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_red.value) == 0, f"Invalid red at horizontal sync pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_green.value) == 0, f"Invalid green at horizontal sync pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_blue.value) == 0, f"Invalid blue at horizontal sync pixel {i}, cycle {j}, {line_info}"

            await ClockCycles(dut.clk, 1)

    # Horizontal back porch
    for i in range(40):
        for j in range(2):
            assert dut.vga_hsync.value == 1, f"Invalid hsync at horizontal back porch pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_vsync.value) == vsync, f"Invalid vsync at horizontal back porch pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_red.value) == 0, f"Invalid red at horizontal back porch pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_green.value) == 0, f"Invalid green at horizontal back porch pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_blue.value) == 0, f"Invalid blue at horizontal back porch pixel {i}, cycle {j}, {line_info}"

            await ClockCycles(dut.clk, 1)

    # Horizontal left border
    for i in range(8):
        for j in range(2):
            assert dut.vga_hsync.value == 1, f"Invalid hsync at horizontal left border pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_vsync.value) == vsync, f"Invalid vsync at horizontal left border pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_red.value) == 0, f"Invalid red at horizontal left border pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_green.value) == 0, f"Invalid green at horizontal left border pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_blue.value) == 0, f"Invalid blue at horizontal left border pixel {i}, cycle {j}, {line_info}"

            await ClockCycles(dut.clk, 1)

    # Horizontal pixels
    for i in range(640):
        for j in range(2):
            assert dut.vga_hsync.value == 1, f"Invalid hsync at horizontal pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_vsync.value) == vsync, f"Invalid vsync at horizontal pixel {i}, cycle {j}, {line_info}"
            if vporch:
                assert int(dut.vga_red.value) == 0, f"Invalid red at horizontal pixel {i}, cycle {j}, {line_info}"
                assert int(dut.vga_green.value) == 0, f"Invalid green at horizontal pixel {i}, cycle {j}, {line_info}"
                assert int(dut.vga_blue.value) == 0, f"Invalid blue at horizontal pixel {i}, cycle {j}, {line_info}"

            await ClockCycles(dut.clk, 1)

    # Horizontal right border
    for i in range(8):
        for j in range(2):
            assert dut.vga_hsync.value == 1, f"Invalid hsync at horizontal right border pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_vsync.value) == vsync, f"Invalid vsync at horizontal right border pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_red.value) == 0, f"Invalid red at horizontal right border pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_green.value) == 0, f"Invalid green at horizontal right border pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_blue.value) == 0, f"Invalid blue at horizontal right border pixel {i}, cycle {j}, {line_info}"

            await ClockCycles(dut.clk, 1)


    # Horizontal front porch
    for i in range(8):
        for j in range(2):
            assert dut.vga_hsync.value == 1, f"Invalid hsync at horizontal front porch pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_vsync.value) == vsync, f"Invalid vsync at horizontal front porch pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_red.value) == 0, f"Invalid red at horizontal front porch pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_green.value) == 0, f"Invalid green at horizontal front porch pixel {i}, cycle {j}, {line_info}"
            assert int(dut.vga_blue.value) == 0, f"Invalid blue at horizontal front porch pixel {i}, cycle {j}, {line_info}"

            await ClockCycles(dut.clk, 1)


async def verify_frame(dut, frame_info: str):
    # Vertical sync
    for i in range(2):
        await verify_line(dut, 0, True, f"vertical sync line {i}, {frame_info}")

    # Vertical back porch
    for i in range(25):
        await verify_line(dut, 1, True, f"vertical back porch line {i}, {frame_info}")

    # Vertical top border
    for i in range(8):
        await verify_line(dut, 1, True, f"vertical top border line {i}, {frame_info}")

    # Vertical pixels
    for i in range(480):
        await verify_line(dut, 1, False, f"vertical pixels line {i}, {frame_info}")

    # Vertical bottom border
    for i in range(8):
        await verify_line(dut, 1, True, f"vertical bottom border line {i}, {frame_info}")

    # Vertical front porch
    for i in range(2):
        await verify_line(dut, 1, True, f"vertical front porch line {i}, {frame_info}")


@cocotb.test()
async def test_signals(dut):
    ram = []
    for i in range(250):
        pixels = 0
        for j in range(4):
            color332 = (i * 4 + j) % 256
            pixels |= color332 << j
        ram.append(pixels)
        #ram.append(0xFFFFFFFF)

    flash = []

    cocotb.start_soon(utils.wishbone_bus(dut, flash, ram))

    dut.config_enabled.value = 1
    dut.config_addr.value = 0x3000000

    await utils.init(dut)

    # Wait for v/hsync
    for i in range(800 * 525 * 2):
        if dut.vga_hsync.value == 0 and dut.vga_vsync.value == 0:
            break

        await ClockCycles(dut.clk, 1)

    assert dut.vga_hsync.value == 0 and dut.vga_vsync.value == 0

    for i in range(3):
        await verify_frame(dut, f"frame {i}")
