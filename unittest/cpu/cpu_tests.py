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
async def test_registers(dut):
    flash = []
    flash.append(utils.lui(utils.X1, 0xAAAAB))
    flash.append(utils.addi(utils.X1, utils.X1, 0xAAA))
    flash.append(utils.lui(utils.X2, 0x55555))
    flash.append(utils.addi(utils.X2, utils.X2, 0x555))
    flash.append(utils.lui(utils.X5, 0xF0000))
    flash.append(utils.lui(utils.X6, 0x0F000))
    flash.append(utils.lui(utils.X7, 0x00F00))
    flash.append(utils.lui(utils.X8, 0x000F0))
    flash.append(utils.lui(utils.X9, 0x0000F))
    flash.append(utils.lui(utils.X10, 0x000001))
    flash.append(utils.addi(utils.X10, utils.X10, 0xF00))
    flash.append(utils.addi(utils.X11, utils.ZERO, 0x0F0))
    flash.append(utils.addi(utils.X12, utils.ZERO, 0x00F))
    flash.append(utils.sw(utils.GP, utils.X1, -1024))
    flash.append(utils.sw(utils.GP, utils.X2, -1020))
    flash.append(utils.sw(utils.GP, utils.X5, -1016))
    flash.append(utils.sw(utils.GP, utils.X6, -1012))
    flash.append(utils.sw(utils.GP, utils.X7, -1008))
    flash.append(utils.sw(utils.GP, utils.X8, -1004))
    flash.append(utils.sw(utils.GP, utils.X9, -1000))
    flash.append(utils.sw(utils.GP, utils.X10, -996))
    flash.append(utils.sw(utils.GP, utils.X11, -992))
    flash.append(utils.sw(utils.GP, utils.X12, -988))

    ram = []
    for i in range(10):
        ram.append(0)

        cocotb.start_soon(utils.wishbone_bus(dut, flash, ram))

    await utils.init(dut)

    await ClockCycles(dut.clk, 10000)

    assert ram[0] == 0xAAAAAAAA
    assert ram[1] == 0x55555555
    assert ram[2] == 0xF0000000
    assert ram[3] == 0x0F000000
    assert ram[4] == 0x00F00000
    assert ram[5] == 0x000F0000
    assert ram[6] == 0x0000F000
    assert ram[7] == 0x00000F00
    assert ram[8] == 0x000000F0
    assert ram[9] == 0x0000000F


@cocotb.test()
async def test_slli(dut):
    count = 256

    flash = []
    flash.append(utils.lui(utils.X1, 0x01000))                  # X0 points to RAM
    flash.append(utils.addi(utils.X2, utils.ZERO, 1))
    flash.append(utils.addi(utils.X5, utils.ZERO, 0))
    flash.append(utils.addi(utils.X6, utils.ZERO, 0))
    flash.append(utils.addi(utils.X7, utils.ZERO, 0))
    flash.append(utils.addi(utils.X8, utils.ZERO, 0))
    flash.append(utils.addi(utils.X9, utils.ZERO, 0))
    flash.append(utils.addi(utils.X10, utils.ZERO, 0))
    flash.append(utils.addi(utils.X11, utils.ZERO, 0))
    flash.append(utils.addi(utils.X12, utils.ZERO, 0))
    flash.append(utils.addi(utils.X13, utils.ZERO, 0))
    flash.append(utils.addi(utils.X14, utils.ZERO, 0))
    flash.append(utils.addi(utils.X15, utils.ZERO, 0))
    for i in range(count):
        flash.append(utils.addi(utils.X5, utils.ZERO, i))       # X5 = i
        for j in range(32):
            flash.append(utils.slli(utils.X6, utils.X5, j))     # X6 = X5 << i
            flash.append(utils.sw(utils.X1, utils.X6, 0))       # X5[0] = X6
            flash.append(utils.addi(utils.X1, utils.X1, 4))     # X5 += 4
    
    flash.append(utils.sw(utils.X1, utils.X2, 0))               # T0[0] = T1
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
            expected_value = (i << j) & 0xFFFFFFFF
            assert ram[i * 32 + j] == expected_value, f"{i} << {j} = {expected_value}"


