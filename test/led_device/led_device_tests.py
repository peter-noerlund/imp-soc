import cocotb
import utils

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


@cocotb.test()
async def test_led(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    flash = bytearray(16 * 1024 * 1024)
    code = [
        utils.lui(utils.X5, 0x02000),
        utils.addi(utils.X6, utils.ZERO, 0x4),
        utils.sw(utils.X5, utils.X6, 0),
        utils.jal(utils.ZERO, 0)
    ]

    for i in range(len(code)):
        instr = code[i]
        flash[i * 4] = instr & 0xFF
        flash[i * 4 + 1] = (instr >> 8) & 0xFF
        flash[i * 4 + 2] = (instr >> 16) & 0xFF
        flash[i * 4 + 3] = (instr >> 24) & 0xFF

    for i in range(len(code) * 4):
        b = flash[i]
        print(f"{b:02X}")

    cocotb.start_soon(utils.memory_device(dut, dut.spi_flash_ss_n, flash))

    psram = bytearray(8 * 1024 * 1024)
    cocotb.start_soon(utils.memory_device(dut, dut.spi_psram_ss_n, psram))

    dut.rst.value = 1

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    await ClockCycles(dut.clk, 10)

    assert dut.led_r.value == 0
    assert dut.led_g.value == 0
    assert dut.led_b.value == 0

    # Wait for code to execute
    await ClockCycles(dut.clk, 1024)

    assert dut.led_r.value == 1
    assert dut.led_g.value == 0
    assert dut.led_b.value == 0
