
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.types import Logic

MASK = 0xF
SHIFT = 4
LOOPS = 8
#ASK = 0x1
#HIFT = 1
#OOPS = 32


async def rf_read_write(dut, rreg0: int, rreg1: int = 0, wreg0: int = 0, wvalue0: int = 0, wreg1: int = 0, wvalue1: int = 0):
    dut.rf_rreq.value = 1
    dut.rf_wreq.value = 0
    
    await ClockCycles(dut.clk, 1)

    dut.rf_rreq.value = 0
    dut.rf_wen0.value = 0 if wreg0 == 0 else 1
    dut.rf_wreg0.value = wreg0
    dut.rf_wen1.value = 0 if wreg1 == 0 else 1
    dut.rf_wreg1.value = wreg1
    dut.rf_rreg0.value = rreg0
    dut.rf_rreg1.value = rreg1

    for i in range(64):
        if dut.rf_ready.value == 1:
            break
        await ClockCycles(dut.clk, 1)

    assert dut.rf_ready.value == 1

    rvalue0 = 0
    rvalue1 = 0
    for i in range(LOOPS):
        dut.rf_wdata0.value = wvalue0 & MASK
        dut.rf_wdata1.value = wvalue1 & MASK
        wvalue0 >>= SHIFT
        wvalue1 >>= SHIFT
        await ClockCycles(dut.clk, 1)
        try:
            rvalue0 |= int(dut.rf_rdata0.value) << (i * SHIFT)
        except:
            pass
        try:
            rvalue1 |= int(dut.rf_rdata1.value) << (i * SHIFT)
        except:
            pass

    dut.rf_rreg0.value = 0

    dut.rf_rreg1.value = 0

    dut.rf_wen0.value = 0
    dut.rf_wreg0.value = 0
    dut.rf_wdata0.value = 0

    dut.rf_wen1.value = 0
    dut.rf_wreg1.value = 0
    dut.rf_wdata1.value = 0

    return (rvalue0, rvalue1)


async def rf_write(dut, wreg0: int, wvalue0: int, wreg1: int = 0, wvalue1: int = 0):
    dut.rf_rreq.value = 0
    dut.rf_wreq.value = 1

    await ClockCycles(dut.clk, 1)

    assert dut.rf_ready.value == 1

    dut.rf_wreq.value = 0
    dut.rf_rreg0.value = 0
    dut.rf_rreg1.value = 0

    dut.rf_wen0.value = 1
    dut.rf_wreg0.value = wreg0
    dut.rf_wdata0.value = wvalue0 & MASK
    wvalue0 >>= SHIFT

    dut.rf_wen1.value = 0 if wreg1 == 0 else 1
    dut.rf_wreg1.value = wreg1
    dut.rf_wdata1.value = wvalue1 & MASK
    wvalue1 >>= SHIFT

    for i in range(LOOPS - 1):
        await ClockCycles(dut.clk, 1)

        dut.rf_wdata0.value = wvalue0 & MASK
        wvalue0 >>= SHIFT

        dut.rf_wdata1.value = wvalue1 & MASK
        wvalue1 >>= SHIFT

    await ClockCycles(dut.clk, 1)

    dut.rf_wreq.value = 0
    dut.rf_wen0.value = 0
    dut.rf_wreg0.value = 0
    dut.rf_wdata0.value = 0
    dut.rf_wen1.value = 0
    dut.rf_wreg1.value = 0
    dut.rf_wdata1.value = 0

@cocotb.test()
async def test_read_write(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    reg_count = 16

    for reg in range(1, reg_count):
        await rf_write(dut, reg, 0)

    for reg in range(reg_count):
        (value0, value1) = await rf_read_write(dut, reg, reg)
        assert value0 == 0
        assert value1 == 0

    for reg in range(reg_count):
        for bit in range(32):
            if reg == 0 or reg == 3 or reg == 4:
                expected_value = 0
            else:
                expected_value = 1 << bit
            await rf_read_write(dut, 0, 0, reg, expected_value)

            (value0, value1) = await rf_read_write(dut, reg, reg)
            assert value0 == expected_value
            assert value1 == expected_value

            for other_reg in range(0, reg):
                if reg == other_reg:
                    continue

                (value0, value1) = await rf_read_write(dut, reg, other_reg)
                assert value0 == expected_value
                assert value1 == 0

                (value0, value1) = await rf_read_write(dut, other_reg, reg)
                assert value0 == 0
                assert value1 == expected_value

        await rf_read_write(dut, 0, 0, reg, 0)


@cocotb.test()
async def test_write_only(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    reg_count = 16

    for reg in range(1, reg_count):
        await rf_write(dut, reg, 0)

    for reg in range(reg_count):
        (value0, value1) = await rf_read_write(dut, reg, reg)
        assert value0 == 0
        assert value1 == 0

    for reg in range(reg_count):
        for bit in range(32):
            if reg == 0 or reg == 3 or reg == 4: # zero, gp and tp are all 0
                expected_value = 0
            else:
                expected_value = 1 << bit
            await rf_write(dut, reg, expected_value)

            (value0, value1) = await rf_read_write(dut, reg, reg)
            assert value0 == expected_value
            assert value1 == expected_value

        await rf_write(dut, reg, 0)


@cocotb.test()
async def test_csr(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)

    reg_count = 16

    for reg in range(1, reg_count):
        await rf_write(dut, reg, 0)

    await rf_write(dut, 0, 0, 33, 0)

    for reg in range(reg_count):
        (value0, value1) = await rf_read_write(dut, reg, 33)
        assert value0 == 0
        assert value1 == 4
        
        (value0, value1) = await rf_read_write(dut, reg, 34)
        assert value0 == 0
        assert value1 == 0

    await rf_write(dut, 0, 0, 32, 0xBEEFDEAD)
    await rf_write(dut, 0, 0, 34, 0xDEADBEEF)

    for reg in range(reg_count):
        (value0, value1) = await rf_read_write(dut, reg, 33)
        assert value0 == 0
        assert value1 == 4
        
        (value0, value1) = await rf_read_write(dut, reg, 34)
        assert value0 == 0
        assert value1 == 0xDEADBEEF

