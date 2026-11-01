import cocotb
import utils

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


@cocotb.test()
async def test_soc_uart(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    flash = bytearray(16 * 1024 * 1024)
    code = [
        utils.lui(utils.T0, 0x02000),               # T0 = 0x02000000
        utils.addi(utils.T1, utils.ZERO, 0x50),     # T1 = 0x50
        utils.sb(utils.T0, utils.T1, 0x4),          # T0[4] = T1
        utils.jal(utils.ZERO, 0)                    # j $+0
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
    
    value = await utils.uart_read_byte(dut, 1000000, 1000000000)

    assert value == 0x50

    await ClockCycles(dut.clk, 10)


