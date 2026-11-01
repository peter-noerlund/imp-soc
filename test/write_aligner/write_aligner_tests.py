
import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_8bit_write(dut):
    dut.wb_in_we.value = 1

    for offset in range(0, 4):
        dut.wb_in_sel.value = 1 << offset

        dut.wb_in_adr.value = 0

        # Test no bits
        dut.wb_in_dat.value = 0
        await Timer(40, "ns")
        assert dut.wb_out_sel.value == 0x1
        assert dut.wb_out_dat.value == 0
        assert dut.wb_out_adr.value == offset

        # Test each bit
        for i in range(0, 8):
            dut.wb_in_dat.value = 1 << (i + offset * 8)
            await Timer(40, "ns")
            assert dut.wb_out_sel.value == 0x1
            assert int(dut.wb_out_dat.value) & 0xFF == 1 << i
            assert dut.wb_out_adr.value == offset

        # Test lower address
        for i in range(0, 4):
            dut.wb_in_adr.value = i << 2
            await Timer(40, "ns")
            assert dut.wb_out_adr.value == (i << 2) + offset

        # Test upper address
        for i in range(2, 32):
            dut.wb_in_adr.value = 1 << i
            await Timer(40, "ns")
            assert dut.wb_out_adr.value == (1 << i) + offset


@cocotb.test()
async def test_16bit_write(dut):
    dut.wb_in_we.value = 1

    for offset in range(0, 4, 2):
        dut.wb_in_sel.value = 0x3 << offset

        dut.wb_in_adr.value = 0

        # Test no bits
        dut.wb_in_dat.value = 0
        await Timer(40, "ns")
        assert dut.wb_out_sel.value == 0x3
        assert dut.wb_out_dat.value == 0
        assert dut.wb_out_adr.value == offset

        # Test each bit
        for i in range(0, 16):
            dut.wb_in_dat.value = 1 << (i + offset * 8)
            await Timer(40, "ns")
            assert dut.wb_out_sel.value == 0x3
            assert int(dut.wb_out_dat.value) & 0xFFFF == 1 << i
            assert dut.wb_out_adr.value == offset

        # Test lower address
        for i in range(0, 4):
            dut.wb_in_adr.value = i << 2
            await Timer(40, "ns")
            assert dut.wb_out_adr.value == (i << 2) + offset

        # Test upper address
        for i in range(2, 32):
            dut.wb_in_adr.value = 1 << i
            await Timer(40, "ns")
            assert dut.wb_out_adr.value == (1 << i) + offset


@cocotb.test()
async def test_32bit_write(dut):
    dut.wb_in_we.value = 1
    dut.wb_in_sel.value = 0xF

    dut.wb_in_adr.value = 0

    # Test no bits
    dut.wb_in_dat.value = 0
    await Timer(40, "ns")
    assert dut.wb_out_sel.value == 0xF
    assert dut.wb_out_dat.value == 0
    assert dut.wb_out_adr.value == 0

    # Test each bit
    for i in range(0, 32):
        dut.wb_in_dat.value = 1 << i
        await Timer(40, "ns")
        assert dut.wb_out_sel.value == 0xF
        assert dut.wb_out_dat.value == 1 << i
        assert dut.wb_out_adr.value == 0

    # Test lower address
    for i in range(0, 4):
        dut.wb_in_adr.value = i << 2
        await Timer(40, "ns")
        assert dut.wb_out_adr.value == i << 2

    # Test upper address
    for i in range(2, 32):
        dut.wb_in_adr.value = 1 << i
        await Timer(40, "ns")
        assert dut.wb_out_adr.value == 1 << i


@cocotb.test()
async def test_read(dut):
    dut.wb_in_we.value = 0

    for sel in (0x1, 0x2, 0x4, 0x8, 0x3, 0xC, 0xF):
        dut.wb_in_sel.value = sel

        dut.wb_in_adr.value = 0

        # Test no bits
        await Timer(40, "ns")
        assert dut.wb_out_sel.value == sel
        assert dut.wb_out_adr.value == 0

        # Test each bit
        for i in range(0, 32):
            await Timer(40, "ns")
            assert dut.wb_out_sel.value == sel
            assert dut.wb_out_adr.value == 0

        # Test lower address
        for i in range(0, 4):
            dut.wb_in_adr.value = i << 2
            await Timer(40, "ns")
            assert dut.wb_out_adr.value == i << 2

        # Test upper address
        for i in range(2, 32):
            dut.wb_in_adr.value = 1 << i
            await Timer(40, "ns")
            assert dut.wb_out_adr.value == 1 << i
