
import cocotb
import random
import utils
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

async def verify_frame(dut, ram: list, offset: int, frame_info: str):
    dut.vgaconfig_addr.value = 0x01000000 + offset * 4

    for line in range(96):
        dut.vgactrl_read_req.value = 1
        await ClockCycles(dut.clk, 1)
        dut.vgactrl_read_req.value = 0

        await ClockCycles(dut.clk, 1024)

        assert dut.wb_cyc.value == 0, "Read has finished after 1024 cycles"

        for word in range(16):
            vram_value = int(dut.vgactrl_memory.value[word * 24 + 23 : word * 24])
            psram_value = ram[offset + line * 16 + word]

            c2 = (psram_value >> 24) & 0x3F
            c1 = (psram_value >> 16) & 0x3F
            g3 = (psram_value >> 12) & 0x07
            g2 = (psram_value >> 8) & 0x07
            g1 = (psram_value >> 4) & 0x07
            g0 = psram_value & 0x07

            expeced_vram_value = (c2 << 18) | (c1 << 12) | (g3 << 9) | (g2 << 6) | (g1 << 3) | g0;

            assert vram_value == expeced_vram_value, f"Video memory is correct at {frame_info} (address 0x{offset * 4 + 0x01000000:08X}), line {line}, word {word} (0x{vram_value:08X} == 0x{expeced_vram_value:08X}, psram = 0x{psram_value:08X}, c1={c1:02X}, c2={c2:02X}, g0={g0}, g1={g1}, g2={g2}, g3={g3})"


def encode(c1: int, c2: int, pixels: list) -> int:
    patterns = [
        [0, 0],
        [1, 0],
        [2, 0],
        [0, 1],
        [1, 1],
        [2, 1],
        [0, 2],
        [2, 2]
    ]

    chunk = ((c1 & 0x3F) << 16) | ((c2 & 0x3F) << 24)
    for i in range(2):
        for j in range(2):
            p0 = pixels[i * 4 + j * 2]
            p1 = pixels[i * 4 + j * 2 + 1]

            val = -1
            for j in range(len(patterns)):
                if patterns[j][0] == p0 and patterns[j][1] == p1:
                    val = j
                    break
            if val == -1:
                raise Exception(f"Invalid pixel pattern [{p0}, {p1}]")

            chunk |= val << (i * 4)

    return chunk


def encode_swipe(c1: int, c2: int) -> list:
    return [
        # [0 0]
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 0, 0]),

        # [1 0]
        encode(c1, c2, [1, 0, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 1, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 1, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 1, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 1, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 1, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 1, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 0, 1]),

        # [2 0]
        encode(c1, c2, [2, 0, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 2, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 2, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 2, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 2, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 2, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 2, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 0, 2]),

        # [0 1]
        encode(c1, c2, [0, 1, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 1, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 1, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 1, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 1, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 1, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 0, 1]),
        encode(c1, c2, [1, 0, 0, 0, 0, 0, 0, 0]),

        # [1 1]
        encode(c1, c2, [1, 1, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 1, 1, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 1, 1, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 1, 1, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 1, 1, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 1, 1, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 1, 1]),
        encode(c1, c2, [1, 0, 0, 0, 0, 0, 0, 1]),

        # [2 1]
        encode(c1, c2, [2, 1, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 2, 1, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 2, 1, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 2, 1, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 2, 1, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 2, 1, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 2, 1]),
        encode(c1, c2, [1, 0, 0, 0, 0, 0, 0, 2]),

        # [0 2]
        encode(c1, c2, [0, 2, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 2, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 2, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 2, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 2, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 2, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 0, 2]),
        encode(c1, c2, [2, 0, 0, 0, 0, 0, 0, 0]),

        # [2 2]
        encode(c1, c2, [2, 2, 0, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 2, 2, 0, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 2, 2, 0, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 2, 2, 0, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 2, 2, 0, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 2, 2, 0]),
        encode(c1, c2, [0, 0, 0, 0, 0, 0, 2, 2]),
        encode(c1, c2, [2, 0, 0, 0, 0, 0, 0, 2])
    ]


@cocotb.test()
async def test_vga_memory(dut):
    dut.vgactrl_read_req.value = 0

    flash = []
    ram = []

    # Word in PSRAM is 00rrggbb_00RRGGBB_0ddd_0ccc_0bbb_0aaa
    # Pattern in VRAM is rrggbb_RRGGBB_ddd_ccc_bbb_aaa

    # First frame is all 1's
    for line in range(96):
        for word in range(16):
            ram.append(0x3F3F7777) # all the ignored bits are 0
    # Pad
    for i in range(128 - 96):
        for word in range(16):
            ram.append(0)

    # Second frame is all 0's
    for line in range(96):
        for word in range(16):
            ram.append(0xC0C08888) # all the ignored bits are 1
    # Pad
    for i in range(128 - 96):
        for word in range(16):
            ram.append(0)

    # Third frame is random
    for line in range(3):
        ram += encode_swipe(0x01, 0x3E)
        ram += encode_swipe(0x02, 0x3D)
        ram += encode_swipe(0x04, 0x3A)
        ram += encode_swipe(0x08, 0x37)
        ram += encode_swipe(0x10, 0x2F)
        ram += encode_swipe(0x20, 0x1F)
    # Pad
    for i in range(128 - 96):
        for word in range(16):
            ram.append(0)

    cocotb.start_soon(utils.wishbone_bus(dut, flash, ram))

    await utils.init(dut)

    # First frame is expected to be garbage as it starts with the second line
    dut.vgaconfig_addr.value = 0
    for line in range(95):
        dut.vgactrl_read_req.value = 1
        await ClockCycles(dut.clk, 1)
        dut.vgactrl_read_req.value = 0
        await ClockCycles(dut.clk, 1024)

    await verify_frame(dut, ram, 0, "frame 1")
    await verify_frame(dut, ram, 16 * 128, "frame 2")
    await verify_frame(dut, ram, 32 * 128, "frame 3")

