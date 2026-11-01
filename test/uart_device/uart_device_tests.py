import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from utils import uart_read_byte, wishbone_write8
   

@cocotb.test()
async def test_uart_device(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    dut.wb_cyc.value = 0
    dut.wb_stb.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    for i in range(256):
        task = cocotb.start_soon(wishbone_write8(dut, 0, i))
        value = await uart_read_byte(dut, 1000000, 1000000000)
        await task
        
        assert i == value
