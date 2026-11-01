
import cocotb
import random
import utils
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

async def verify_frame(dut, ram: list, offset: int, frame_info: str):
    dut.vgaconfig_addr.value = 0x01000000 + offset * 4

    for line in range(100):
        dut.read_req.value = 1
        await ClockCycles(dut.clk, 1)
        dut.read_req.value = 0

        await ClockCycles(dut.clk, 1024)

        assert dut.wb_cyc.value == 0, "Read has finished after 1024 cycles"

        for word in range(15):
            value = int(dut.memory.value[word * 32 + 31 : word * 32])
            expected_value = ram[offset + line * 16 + word]
            assert value == expected_value, f"Video memory is correct at {frame_info} (offset {offset}), line {line}, word {word} (0x{value:08X} == 0x{expected_value:08X})"

@cocotb.test()
async def test_vga_memory(dut):
    dut.read_req.value = 0

    flash = []
    ram = []

    # First frame is all 1's
    for line in range(100):
        for word in range(15):
            ram.append(0xFFFFFFFF)
        ram.append(0) # Must be ignored
    # Padding
    for line in range(28):
        for word in range(16):
            ram.append(0)

    # Second frame is all 0's
    for line in range(100):
        for word in range(15):
            ram.append(0)
        ram.append(0xFFFFFFFF) # Must be ignored
    # Padding
    for line in range(28):
        for word in range(16):
            ram.append(0)

    # Third frame is random
    for line in range(100):
        for word in range(15):
            ram.append(random.randint(0, 0xFFFFFFFF))
    # Padding
    for line in range(28):
        for word in range(16):
            ram.append(0)

    cocotb.start_soon(utils.wishbone_bus(dut, flash, ram))

    await utils.init(dut)

    # First frame is expected to be garbage as it starts with the second line
    dut.vgaconfig_addr.value = 0
    for line in range(99):
        dut.read_req.value = 1
        await ClockCycles(dut.clk, 1)
        dut.read_req.value = 0
        await ClockCycles(dut.clk, 1024)

    await verify_frame(dut, ram, 0, "white frame")
    await verify_frame(dut, ram, 16 * 128, "blank frame")
    await verify_frame(dut, ram, 32 * 128, "random frame")

