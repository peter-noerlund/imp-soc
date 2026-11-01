
import cocotb
import utils
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


# r1 r1 g1 g1 b1 b1 r2 r2  g2 g2 b2 b2 p1 p1 p1 p2  p2 p2 p3 p3 p3 p4 p4 p4

def encode_group(p0: int, p1: int) -> int:
    if p1 == 0:
        if p0 == 0:
            return 0
        elif p0 == 1:
            return 1
        elif p0 == 2:
            return 2
    elif p1 == 1:
        if p0 == 0:
            return 3
        elif p0 == 1:
            return 4
        elif p0 == 2:
            return 5
    elif p1 == 2:
        if p0 == 0:
            return 6
        elif p0 == 2:
            return 7
    raise Exception("Invalid pixel group")


def encode_chunk(color1: int, color2: int, pixels: list) -> int:
    p = [
        encode_group[pixels[0], pixels[1]],
        encode_group[pixels[2], pixels[3]],
        encode_group[pixels[4], pixels[5]],
        encode_group[pixels[6], pixels[7]]
    ]

    v0 = (color1 << 2) | (color2 >> 4)
    v1 = (color2 << 4) | (p[0] << 1) | (p[1] >> 2)
    v2 = ((p[1] & 0x03) << 6) | (p[2] << 3) | p[3];

    return [v0, v1, v2]


def encode_chunks(chunks: list) -> list:
    res = []
    for chunk in chunks:
        res += encode_chunk(chunk[0], chunk[1], chunk[2])

    return res


def decode_chunk(chunk: int): list
    color1 = (chunk >> 18) & 0xFFF
    color2 = (chunk >> 12) & 0xFFF

    pixels = []
    for i in range(4):
        group = (chunk >> (i * ))


def decode_chunks(chunks: list) -> list
    pass


async def verify_line(dut, chunks: list):
    memory = 0

    for i in range(15):
        memory |= groups[i] << (i * 24)

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

    # Verify 640 black pixels
    for i in range(640):
        assert int(dut.vga_red.value) == 0
        assert int(dut.vga_green.value) == 0
        assert int(dut.vga_blue.value) == 0
        await ClockCycles(dut.clk, 1)


    pass


@cocotb.test()
async def test_pixel_decoding(dut):
    await utils.init(dut)

    patterns = [
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0],
    ]

    for pattern in 

    await verify_line(dut, encode_chunks(
        [0x00, 0x00, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x00, 0x01, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x00, 0x02, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x00, 0x04, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x00, 0x08, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x00, 0x10, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x00, 0x20, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x01, 0x00, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x02, 0x00, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x04, 0x00, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x08, 0x00, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x10, 0x00, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x20, 0x00, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x00, 0x00, [0, 0, 0, 0, 0, 0, 0, 0]],
        [0x00, 0x00, [0, 0, 0, 0, 0, 0, 0, 0]]
    ))

    