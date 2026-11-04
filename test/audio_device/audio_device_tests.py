import cocotb
import utils
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def verify_waveform(dut, count: int):

    await utils.wishbone_write32(dut, 0, count)

    val0 = int(dut.audio_out.value)
    val1 = 1 if val0 == 0 else 0

    for i in range(count + 1):
        if dut.audio_out.value == val1:
            break
        await ClockCycles(dut.clk, 1)

    assert dut.audio_out.value == val1, f"audio_out must flip within {count + 1} cycles (count={count})"

    for j in range(3):
        for i in range(count + 1):
            assert dut.audio_out.value == val1, f"audio_out must stay stable after {i} cycles, the {j}th time (count={count})"
            await ClockCycles(dut.clk, 1)
    
        for i in range(count + 1):
            assert dut.audio_out.value == val0, f"audio_out must stay stable after {i} cycles, the {j}th time (count={count})"
            await ClockCycles(dut.clk, 1)
 
@cocotb.test()
async def test_vga_device(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    dut.wb_cyc.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10);

    await verify_waveform(dut, 100)
    await verify_waveform(dut, 200)
    await verify_waveform(dut, 300)
