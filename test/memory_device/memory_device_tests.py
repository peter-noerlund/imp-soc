import cocotb
import math
import random

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from utils import memory_device, wishbone_read8, wishbone_read16, wishbone_read32, wishbone_write8, wishbone_write16, wishbone_write32


async def test_single_read(dut, address: int, expected_value: int):
    # 32-bit read
    value = await wishbone_read32(dut, address)
    assert value == expected_value

    # 16-bit read
    value = await wishbone_read16(dut, address)
    assert value == expected_value & 0xFFFF

    value = await wishbone_read16(dut, address + 2)
    assert value == (expected_value >> 16) & 0xFFFF

    # 8-bit read
    value = await wishbone_read8(dut, address)
    assert value == expected_value & 0xFF

    value = await wishbone_read8(dut, address + 1)
    assert value == (expected_value >> 8) & 0xFF

    value = await wishbone_read8(dut, address + 2)
    assert value == (expected_value >> 16) & 0xFF

    value = await wishbone_read8(dut, address + 3)
    assert value == (expected_value >> 24) & 0xFF


async def test_read(dut, memory: bytearray, base_address: int):
    memory_size = len(memory)
    address_bits = int(math.log2(memory_size)) - 2

    await test_single_read(dut, base_address, int.from_bytes(memory[0:4], byteorder="little"))

    # Verify each address bit    
    for i in range(address_bits):
        address = 4 << i
        expected_value = int.from_bytes(memory[address : address + 4], byteorder="little")
        await test_single_read(dut, base_address + address, expected_value)

    await test_single_read(dut, base_address + memory_size - 4, int.from_bytes(memory[memory_size - 4 : memory_size], byteorder="little"))

    # Verify each data bit
    for i in range(32):
        while True:
            j = random.randrange(0, memory_size // 4)

            address = j * 4
            expected_value = int.from_bytes(memory[address : address + 4], byteorder="little")

            if expected_value & (1 << i) == 0:
                continue

            await test_single_read(dut, base_address + address, expected_value)
            break


async def test_write(dut, memory: bytearray, base_address: int):
    memory_size = len(memory)

    history = {}
    for i in range(32):
        while True:
            address = base_address + random.randrange(0, memory_size // 4) * 4
            if address not in history:
                break

        value = 1 << i
        await wishbone_write32(dut, address, value)
        history[address] = (value, 32)

    for i in range(2):
        mask = 0x3 if i == 0 else 0xC
        for j in range(16):
            while True:
                address = base_address + random.randrange(0, memory_size // 4) * 4 + i * 2
                if address not in history:
                    break
            
            value = 1 << j
            await wishbone_write16(dut, address, value)
            history[address] = (value, 16)

    for i in range(4):
        for j in range(256):
            while True:
                address = base_address + random.randrange(0, memory_size // 4) * 4 + i
                if address not in history:
                    break
            
            value = j
            await wishbone_write8(dut, address, value)
            history[address] = (value, 8)

    for address, info in history.items():
        expected_value = info[0]
        size = info[1]
        if size == 8:
            value = await wishbone_read8(dut, address)
        elif size == 16:
            value = await wishbone_read16(dut, address)
        elif size == 32:
            value = await wishbone_read32(dut, address)
        else:
            raise Exception(f"Unexpected size: {size}")
        assert value == expected_value


@cocotb.test()
async def test_memory_device(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    flash = bytearray(16 * 1024 * 1024)
    for i in range(16 * 1024 * 1024):
        flash[i] = random.randrange(256)
    cocotb.start_soon(memory_device(dut, dut.spi_flash_ss_n, flash))

    psram = bytearray(8 * 1024 * 1024)
    for i in range(8 * 1024 * 1024):
        psram[i] = random.randrange(256)
    cocotb.start_soon(memory_device(dut, dut.spi_psram_ss_n, psram))

    dut.rst.value = 1
    dut.wb_cyc.value = 0
    dut.wb_stb.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    await test_read(dut, flash, 0)
    await test_read(dut, psram, 0x1000000)

    await test_write(dut, psram, 0x1000000)