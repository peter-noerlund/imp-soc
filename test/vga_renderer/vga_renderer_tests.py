
import cocotb
import random
import utils
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


def decode_line_buffer(blocks: list) -> list:
    # c1 c1 c1 c1 c1 c1 c2 c2  c2 c2 c2 c2 g1 g1 g1 g2  g2 g2 g3 g3 g3 g4 g4 g4
    out = []

    for i in range(20):
        block = (blocks[i * 3] << 16) | (blocks[i * 3 + 1] << 8) | blocks[i * 3 + 2]

        c1 = (block >> 18) & 0x3F
        c2 = (block >> 12) & 0x3F
        pixels = block & 0xFFF

        print(f"block=0x{block:06x}, c1=0x{c1:02x}, c2=0x{c2:02x}, pixels=0x{pixels:03x}")

        for j in range(4):
            group = (pixels & 0xE00) >> 9

            print(f"group={group:x}")

            if group == 0:
                out += [0, 0]
            elif group == 1:
                out += [c1, 0]
            elif group == 2:
                out += [c2, 0]
            elif group == 3:
                out += [0, c1]
            elif group == 4:
                out += [c1, c1]
            elif group == 5:
                out += [c2, c1]
            elif group == 6:
                out += [0, c2]
            else:
                out += [c2, c2]

            pixels <<= 3
    
    return out


async def verify_line(dut, line_buffer: list):
    memory = 0

    for i in range(60):
        memory |= line_buffer[i] << (i * 8)

    dut.vgactrl_memory.value = memory

    # Wait for hsync
    for i in range(1536):
        if dut.vga_hsync.value == 0:
            break
        await ClockCycles(dut.clk, 1)
    assert dut.vga_hsync.value == 0

    # Wait for hsync to finish
    for i in range(320):
        if dut.vga_hsync.value == 1:
            break
        await ClockCycles(dut.clk, 1)
    assert dut.vga_hsync.value == 1

    # Wait for pixels
    await ClockCycles(dut.clk, 160 + 192)

    decoded_line = decode_line_buffer(line_buffer)

    print(line_buffer)
    print(decoded_line)

    # Verify 640 black pixels
    for i in range(640):
        pixel_idx = i // 4
        pixel = decoded_line[pixel_idx]
        red = pixel >> 4
        green = (pixel >> 2) & 0x3
        blue = pixel & 0x3

        block_idx = pixel_idx // 20
        block = line_buffer[block_idx * 3 : block_idx * 3 + 3]

        print(f"pixel_idx={pixel_idx} block_idx={block_idx}, pixel={pixel:02x}")

        assert int(dut.vga_red.value) == red, f"Pixel {i} should have color 0x{pixel:06x} (red={red}, block={block[0]:02x}{block[1]:02x}{block[2]:02x})"
        assert int(dut.vga_green.value) == green, f"Pixel {i} should have color 0x{pixel:06x} (green={green}, block={block[0]:02x}{block[1]:02x}{block[2]:02x})"
        assert int(dut.vga_blue.value) == blue, f"Pixel {i} should have color 0x{pixel:06x} (blue={blue}, block={block[0]:02x}{block[1]:02x}{block[2]:02x})"
        await ClockCycles(dut.clk, 1)


@cocotb.test()
async def test_pixel_decoding(dut):
    await utils.init(dut)

    # Test all black (c1=[0 0 0], c2=[0 0 0], p=[0 0 0 0 0 0 0 0]) => 000000_000000_000_000_000_000 => 00000000_00000000_00000000
    line_buffer = []
    for i in range(60):
        line_buffer.append(0)
    await verify_line(dut, line_buffer)

    # Test all white (c1=[3 3 3], c2=[0 0 0], p=[1 1 1 1 1 1 1 1]) => 111111_000000_100_100_100_100 => 11111100_00000010_01001001
    line_buffer = []
    for i in range(20):
        line_buffer.append(0xFC)
        line_buffer.append(0x09)
        line_buffer.append(0x24)
    await verify_line(dut, line_buffer)

    # Test random
    for i in range(3):
        line_buffer = []
        for j in range(60):
            line_buffer.append(random.randint(0, 255))
        await verify_line(dut, line_buffer)
