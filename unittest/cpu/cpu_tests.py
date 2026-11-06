import cocotb
import utils

from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_store(dut):
    flash = []
    flash.append(utils.lui(utils.T0, 0x01000))
    flash.append(utils.sb(utils.T0, utils.ZERO, 0))  # adr=00, sel=0001
    flash.append(utils.sb(utils.T0, utils.ZERO, 5))  # adr=04, sel=0010
    flash.append(utils.sb(utils.T0, utils.ZERO, 10)) # adr=08, sel=0100
    flash.append(utils.sb(utils.T0, utils.ZERO, 15)) # adr=0C, sel=1000
    flash.append(utils.sh(utils.T0, utils.ZERO, 16)) # adr=10, sel=0011
    flash.append(utils.sh(utils.T0, utils.ZERO, 22)) # adr=14, sel=1100
    flash.append(utils.sw(utils.T0, utils.ZERO, 24)) # adr=18, sel=1111
    flash.append(utils.jal(utils.ZERO, 0))

    ram = []
    for i in range(7):
        ram.append(0xFFFFFFFF)

    cocotb.start_soon(utils.wishbone_bus(dut, flash, ram))

    await utils.init(dut)

    await ClockCycles(dut.clk, 2000)

    assert ram[0] == 0xFFFFFF00
    assert ram[1] == 0xFFFF00FF
    assert ram[2] == 0xFF00FFFF
    assert ram[3] == 0x00FFFFFF
    assert ram[4] == 0xFFFF0000
    assert ram[5] == 0x0000FFFF
    assert ram[6] == 0x00000000


@cocotb.test()
async def test_slli(dut):
    count = 256

    flash = []
    flash.append(utils.lui(utils.T0, 0x01000))                  # T0 points to RAM
    for i in range(count):
        flash.append(utils.addi(utils.T1, utils.ZERO, i))       # T1 = i
        for j in range(32):
            flash.append(utils.slli(utils.T2, utils.T1, j))     # T2 = T1 << i
            flash.append(utils.sw(utils.T0, utils.T2, 0))       # T0[0] = T3
            flash.append(utils.addi(utils.T0, utils.T0, 4))     # T0 += 4
    
    flash.append(utils.addi(utils.T1, utils.ZERO, 1))           # T1 = 1
    flash.append(utils.sw(utils.T0, utils.T1, 0))               # T0[0] = T1
    flash.append(utils.jal(utils.ZERO, 0))                      # J $+0

    ram = []
    for i in range(count * 32 + 1):
        ram.append(0)

    cocotb.start_soon(utils.wishbone_bus(dut, flash, ram))

    await utils.init(dut)

    while True:
        await ClockCycles(dut.clk, 10000)
        if ram[count * 32] == 1:
            break

    for i in range(count):
        for j in range(32):
            assert ram[i * 32 + j] == (i << j) & 0xFFFFFFFF