import cocotb
import utils
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def verify_timer(dut, count: int):
    await utils.wishbone_write32(dut, 0, count)

    assert dut.irq_out.value == 0, "irq_out is 0 after a write"

    for i in range(count - 10):
        assert dut.irq_out.value == 0, f"irq_out remains 0 after {i} cycles (count={count})"
        await ClockCycles(dut.clk, 1)

    for i in range(10):
        if dut.irq_out.value == 1:
            break
        await ClockCycles(dut.clk, 1)
    
    assert dut.irq_out.value == 1, f"irq_out is triggered"


@cocotb.test()
async def test_vga_device(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    dut.wb_cyc.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10);

    await verify_timer(dut, 100)
    await verify_timer(dut, 200)
    await verify_timer(dut, 300)
