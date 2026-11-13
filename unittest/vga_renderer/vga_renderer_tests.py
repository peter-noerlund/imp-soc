
import cocotb
import random
import utils
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


def decode_line(line_buffer: list) -> list:
    line = []
    for i in range(16):
        chunk = line_buffer[i]
        c2 = (chunk >> 22) & 0x3F;
        c1 = (chunk >> 16) & 0x3F;
        pixels = chunk & 0xFFFF
        for j in range(8):
            pixel_idx = (pixels >> (j * 2)) & 0x03
            if pixel_idx == 1:
                line.append(c1)
            elif pixel_idx == 2:
                line.append(c2)
            else:
                line.append(0)
    return line


async def verify_line(dut, line_buffer: list):
    memory = 0

    for i in range(16):
        memory |= line_buffer[i] << (i * 28)

    dut.vgactrl_memory.value = memory

    # Wait for hsync
    for i in range(1024 + 24 + 136 + 160):
        if dut.vga_hsync.value == 0:
            break
        await ClockCycles(dut.clk, 1)
    assert dut.vga_hsync.value == 0

    # Wait for hsync to finish
    for i in range(160):
        if dut.vga_hsync.value == 1:
            break
        await ClockCycles(dut.clk, 1)
    assert dut.vga_hsync.value == 1

    # Wait for pixels
    await ClockCycles(dut.clk, 160)

    pixels = decode_line(line_buffer)

    # Verify 1024 pixels
    for i in range(1024):
        pixel_idx = i // 8
        pixel = pixels[pixel_idx]
        red = pixel >> 4
        green = (pixel >> 2) & 0x3
        blue = pixel & 0x3

        assert int(dut.vga_red.value) == red, f"Pixel {i} should have color 0x{pixel:06x} (red={red}, line={pixels}, line_buffer={line_buffer})"
        assert int(dut.vga_green.value) == green, f"Pixel {i} should have color 0x{pixel:06x} (green={green})"
        assert int(dut.vga_blue.value) == blue, f"Pixel {i} should have color 0x{pixel:06x} (blue={blue})"
        await ClockCycles(dut.clk, 1)


def encode_sram(c1: int, c2: int, pixels: list) -> int:
    chunk = ((c2 & 0x3F) << 24) | ((c2 & 0x3F) << 16)
    for i in range(8):
        chunk |= (pixels[i] & 0x03) << (i * 2)
    return chunk


def sram_to_vram(chunk: int) -> int:
    c2 = (chunk >> 24) & 0x3F
    c1 = (chunk >> 16) & 0x3F;
    pixels = chunk & 0xFFFF;

    return (c2 << 22) | (c1 << 16) | pixels;


@cocotb.test()
async def test_pixel_decoding(dut):
    await utils.init(dut)

    line_buffer = []
    for i in range(16):
        line_buffer.append(0)
    await verify_line(dut, line_buffer)

    line_buffer = []
    for i in range(16):
        line_buffer.append(sram_to_vram(encode_sram(0, 0x3F, [1, 1, 1, 1, 1, 1, 1, 1])))
    await verify_line(dut, line_buffer)

    # Test random
    for i in range(3):
        line_buffer = []
        for j in range(16):
            line_buffer.append(random.randint(0, 268435455))
        await verify_line(dut, line_buffer)
