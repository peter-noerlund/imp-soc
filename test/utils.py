import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, First, Timer, RisingEdge


async def init(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


async def wishbone_operation(dut, address: int, size: int, write: bool = False, value: int = 0) -> int:
    dut.wb_we.value = 1 if write else 0

    if size == 8:
        dut.wb_adr.value = address & ~0x3
        lsb = address & 0x3
        if lsb == 0:
            mask = 0x1
            dut.wb_dat.value = value & 0xFF
        elif lsb == 1:
            mask = 0x2
            dut.wb_dat.value = (value & 0xFF) << 8
        elif lsb == 2:
            mask = 0x4
            dut.wb_dat.value = (value & 0xFF) << 16
        else:
            mask = 0x8
            dut.wb_dat.value = (value & 0xFF) << 24
    elif size == 16:
        assert address & 0x1 == 0

        dut.wb_adr.value = address & ~0x3
        if address & 0x2 == 0:
            mask = 0x3
            dut.wb_dat.value = value & 0xFFFF
        else:
            mask = 0xC
            dut.wb_dat.value = (value & 0xFFFF) << 16
    elif size == 32:
        assert address & 0x3 == 0

        dut.wb_adr.value = address
        mask = 0xF
        dut.wb_dat.value = value
    else:
        raise Exception(f"Invalid size: {size}")

    dut.wb_sel.value = mask

    dut.wb_cti.value = 0
    dut.wb_bte.value = 0

    dut.wb_cyc.value = 1
    dut.wb_stb.value = 1

    for clock in range(1000):
        await ClockCycles(dut.clk, 1)

        if dut.wb_ack.value == 1 or dut.wb_err.value == 1 or dut.wb_rty.value == 1:
            break

    ack = dut.wb_ack.value
    err = dut.wb_err.value
    rty = dut.wb_rty.value
    rdt = int(dut.wb_rdt.value)

    dut.wb_stb.value = 0
    dut.wb_cyc.value = 0

    await ClockCycles(dut.clk, 1)

    if rty:
        raise Exception("Wishbone retry error")

    if err:
        raise Exception("Wishbone error")

    if ack != 1:
        raise Exception("Wishbone stall")

    if mask == 0xF:
        return rdt
    elif mask == 0x3:
        return rdt & 0xFFFF
    elif mask == 0xC:
        return (rdt >> 16) & 0xFFFF
    elif mask == 0x1:
        return rdt & 0xFF
    elif mask == 0x2:
        return (rdt >> 8) & 0xFF
    elif mask == 0x4:
        return (rdt >> 16) & 0xFF
    elif mask == 0x8:
        return (rdt >> 24) & 0xFF
    else:
        raise Exception(f"Unspected mask: 0x{mask:x}")


async def wishbone_read8(dut, address: int) -> int:
    return await wishbone_read(dut, address, 8)


async def wishbone_read16(dut, address: int) -> int:
    return await wishbone_read(dut, address, 16)


async def wishbone_read32(dut, address: int) -> int:
    return await wishbone_read(dut, address, 32)


async def wishbone_read(dut, address: int, size: int) -> int:
    return await wishbone_operation(dut, address, size)


async def wishbone_write8(dut, address: int, value: int):
    await wishbone_write(dut, address, value, 8)


async def wishbone_write16(dut, address: int, value: int):
    await wishbone_write(dut, address, value, 16)


async def wishbone_write32(dut, address: int, value: int):
    await wishbone_write(dut, address, value, 32)


async def wishbone_write(dut, address: int, value: int, size: int):
    await wishbone_operation(dut, address, size, True, value)


async def wishbone_bus(dut, flash: list, ram: list, ram_address: int = 0x1000000, flash_address: int = 0):
    dut.wb_err.value = 0
    dut.wb_rty.value = 0

    while True:
        await ClockCycles(dut.clk, 1)
        if dut.wb_cyc.value == 0 or dut.wb_stb.value == 0 or dut.wb_ack.value == 1:
            dut.wb_ack.value = 0
            continue

        if dut.rst.value != 0:
            dut.wb_ack.value = 0
            continue

        await ClockCycles(dut.clk, 56)

        adr = int(dut.wb_adr.value)

        if adr >= flash_address and adr < flash_address + len(flash) * 4:
            offset = (adr - flash_address) // 4
            dut.wb_rdt.value = flash[offset]
        elif adr >= ram_address and adr < ram_address + len(ram) * 4:
            offset = (adr - ram_address) // 4
            mask = 0
            if dut.wb_we.value == 1:
                sel = int(dut.wb_sel.value)
                dat = int(dut.wb_dat.value)
                for i in range(4):
                    if sel & (1 << i) != 0:
                        mask |= 0xFF << (i * 8)

                value = (ram[offset] & ~mask) | (dat & mask);
                #print(f"adr=0x{adr:x} offset=0x{offset:x} dat=0x{dat:x} sel=0x{sel:x} mask=0x{mask:x} value=0x{value:x}")

                ram[offset] = value

            dut.wb_rdt.value = ram[offset]
        else:
            dut.wb_rdt.value = 0

        dut.wb_ack.value = 1


async def memory_device(dut, ss_n, memory: bytearray):
    while True:
        await FallingEdge(ss_n)
        assert dut.spi_sck.value == 0

        command = 0

        for i in range(8):
            await First(RisingEdge(dut.spi_sck), RisingEdge(ss_n))
            assert ss_n.value == 0

            assert dut.spi_sio_oe.value == 0x1
            command = (command << 1) | int(dut.spi_sio_out[0].value)

        assert command == 0xEB or command == 0x38

        address = 0

        for i in range(6):
            await First(RisingEdge(dut.spi_sck), RisingEdge(ss_n))
            assert ss_n.value == 0
            assert dut.spi_sio_oe.value == 0xF

            address = (address << 4) | int(dut.spi_sio_out.value)

        assert address < len(memory)

        if command == 0x38: # Write Quad
            while True:
                await First(RisingEdge(dut.spi_sck), RisingEdge(ss_n))
                if ss_n.value == 1:
                    break

                assert dut.spi_sio_oe.value == 0xF
                b = int(dut.spi_sio_out.value) << 4
                
                await First(RisingEdge(dut.spi_sck), RisingEdge(ss_n))
                if ss_n.value == 1:
                    break
                assert dut.spi_sio_oe.value == 0xF
                
                b |= int(dut.spi_sio_out.value)

                memory[address] = b

                address += 1
        else: # Fast Read Quad
            await First(FallingEdge(dut.spi_sck), RisingEdge(ss_n))
            assert ss_n.value == 0

            for i in range(6):
                await First(FallingEdge(dut.spi_sck), RisingEdge(ss_n))
                assert ss_n.value == 0
                assert dut.spi_sio_oe.value == 0x0

            while True:
                b = memory[address % len(memory)]
                
                assert dut.spi_sio_oe.value == 0

                dut.spi_sio_in.value = (b >> 4)

                await First(FallingEdge(dut.spi_sck), RisingEdge(ss_n))
                if ss_n.value == 1:
                    break
                assert dut.spi_sio_oe.value == 0

                dut.spi_sio_in.value = b & 0x0F

                await First(FallingEdge(dut.spi_sck), RisingEdge(ss_n))
                if ss_n.value == 1:
                    break
                assert dut.spi_sio_oe.value == 0

                address += 1


async def uart_read_byte(dut, baudrate: int, timeout: int = 0) -> int:
    cycle_time = 1000000000 // baudrate
    
    assert dut.uart_tx.value == 1

    # Wait for start bit
    if timeout == 0:
        await FallingEdge(dut.uart_tx)
    else:
        await First(FallingEdge(dut.uart_tx), Timer(timeout, unit="ns"))
        assert dut.uart_tx.value == 0

    # Wait for the entirety of the start bit and half the first data bit
    await Timer(cycle_time + cycle_time // 2, unit="ns")

    value = 0
    for j in range(0, 8):
        value = (value >> 1) | (0x80 if dut.uart_tx.value == 1 else 0x00)
        await Timer(cycle_time, unit="ns")

    assert dut.uart_tx.value == 1

    await Timer(cycle_time // 2, unit="ns")

    return value


X0 = 0
ZERO = 0
X1 = 1
RA = 1
X2 = 2
SP = 2
X3 = 3
GP = 3
X4 = 4
TP = 4
X5 = 5
T0 = 5
X6 = 6
T1 = 6
X7 = 7
T2 = 7
X8 = 8
S0 = 8
X9 = 9
S1 = 9
X10 = 10
A0 = 10
X11 = 11
A1 = 11
X12 = 12
A2 = 12
X13 = 13
A3 = 13
X14 = 14
A4 = 14
X15 = 15
A5 = 15


LOAD =      0x03    # 00_000_11
LOAD_FP =   0x07    # 00_001_11
CUSTOM_0 =  0x0B    # 00_010_11
MISC_MEM =  0x0F    # 00_011_11

IMM =       0x13    # 00_100_11
AUIPC =     0x17    # 00_101_11
IMM_32 =    0x1B    # 00_110_11

STORE =     0x23    # 01_000_11
STORE_FP =  0x27    # 01_001_11
CUSTOM_1 =  0x2B    # 01_010_11
AMO =       0x2F    # 01_011_11

OP =        0x33    # 01_100_11
LUI =       0x37    # 01_101_11
OP_32 =     0x3B    # 01_110_11

MADD =      0x43    # 10_000_11
MSUB =      0x47    # 10_001_11
NMSUB =     0x4B    # 10_010_11
NMADD =     0x4F    # 10_011_11
OP_FP =     0x53    # 10_100_11
OP_V =      0x57    # 10_101_11
CUSTOM_2 =  0x5B    # 10_110_11

BRANCH =    0x63    # 11_000_11
JALR =      0x67    # 11_001_11
JAL =       0x6F    # 11_011_11
SYSTEM =    0x73    # 11_100_11
OP_VE =     0x77    # 11_101_11
CUSTOM_3 =  0x7B    # 11_110_11

def _op_r(opcode: int, funct3: int, funct7: int, rd: int, rs1: int, rs2: int) -> int:
    return opcode | (rd << 7) | (funct3 << 12) | (rs1 << 15) | (rs2 << 20) | (funct7 << 25)


def _op_i(opcode: int, funct3: int , rd: int, rs1: int, imm: int) -> int:
    return opcode | (rd << 7) | (funct3 << 12) | (rs1 << 15) | (imm << 20)


def _op_s(opcode: int, funct3: int, rs1: int, rs2: int, imm: int) -> int:
    return opcode | ((imm & 0x1F) << 7) | (funct3 << 12) | (rs1 << 15) | (rs2 << 20) | ((imm >> 5) << 25)


def _op_b(opcode: int, funct3: int, rs1: int, rs2: int, imm: int) -> int:
    return opcode | (((imm >> 11) & 0x1) << 7) | (((imm >> 1) & 0x0F) << 8) | (funct3 << 12) | (rs1 << 15) | (rs2 << 20) | (((imm >> 5) & 0x3F) << 25) | (((imm >> 12) & 0x01) << 30)


def _op_u(opcode: int, rd: int, imm: int) -> int:
    return opcode | (rd << 7) | ((imm & 0xFFFFF) << 12)


def _op_j(opcode: int, rd: int, imm: int) -> int:
    return opcode | (rd << 7) | (((imm >> 12) & 0xFF) << 12) | (((imm >> 11) & 0x1) << 20) | (((imm >> 1) & 0x3FF) << 21) | (((imm >> 20) & 0x01) << 30)


def lui(rd: int, imm: int) -> int:
    return _op_u(LUI, rd, imm)


def auipc(rd: int, imm: int) -> int:
    return _op_u(AUIPC, rd, imm)


def jal(rd: int, imm: int) -> int:
    return _op_j(JAL, rd, imm)


def jalr(rd: int, rs1: int, imm: int) -> int:
    return _op_i(JALR, rd, rs1, imm)


def beq(rs1: int, rs2: int, imm: int) -> int:
    return _op_b(BRANCH, 0, rs1, rs2, imm)


def bne(rs1: int, rs2: int, imm: int) -> int:
    return _op_b(BRANCH, 1, rs1, rs2, imm)


def blt(rs1: int, rs2: int, imm: int) -> int:
    return _op_b(BRANCH, 4, rs1, rs2, imm)


def bge(rs1: int, rs2: int, imm: int) -> int:
    return _op_b(BRANCH, 5, rs1, rs2, imm)


def bltu(rs1: int, rs2: int, imm: int) -> int:
    return _op_b(BRANCH, 6, rs1, rs2, imm)


def bgeu(rs1: int, rs2: int, imm: int) -> int:
    return _op_b(BRANCH, 7, rs1, rs2, imm)


def lb(rd: int, rs1: int, imm: int) -> int:
    return _op_i(LOAD, 0, rd, rs, imm)


def lh(rd: int, rs1: int, imm: int) -> int:
    return _op_i(LOAD, 1, rd, rs, imm)


def lw(rd: int, rs1: int, imm: int) -> int:
    return _op_i(LOAD, 2, rd, rs, imm)


def lbu(rd: int, rs1: int, imm: int) -> int:
    return _op_i(LOAD, 4, rd, rs, imm)


def lhu(rd: int, rs1: int, imm: int) -> int:
    return _op_i(LOAD, 5, rd, rs, imm)


def sb(rs1: int, rs2: int, imm: int) -> int:
    return _op_s(STORE, 0, rs1, rs2, imm)


def sh(rs1: int, rs2: int, imm: int) -> int:
    return _op_s(STORE, 1, rs1, rs2, imm)


def sw(rs1: int, rs2: int, imm: int) -> int:
    return _op_s(STORE, 2, rs1, rs2, imm)


def addi(rd: int, rs1: int, imm: int) -> int:
    return _op_i(IMM, 0, rd, rs1, imm)


def slti(rd: int, rs1: int, imm: int) -> int:
    return _op_i(IMM, 2, rd, rs1, imm)


def sltiu(rd: int, rs1: int, imm: int) -> int:
    return _op_i(IMM, 3, rd, rs1, imm)


def xori(rd: int, rs1: int, imm: int) -> int:
    return _op_i(IMM, 4, rd, rs1, imm)


def ori(rd: int, rs1: int, imm: int) -> int:
    return _op_i(IMM, 6, rd, rs1, imm)


def andi(rd: int, rs1: int, imm: int) -> int:
    return _op_i(IMM, 7, rd, rs1, imm)


def slli(rd: int, rs1: int, shamt: int) -> int:
    return _op_r(IMM, 1, 0x00, rd, rs1, shamt)


def srli(rd: int, rs1: int, shamt: int) -> int:
    return _op_r(IMM, 5, 0x00, rd, rs1, shamt)


def srai(rd: int, rs1: int, shamt: int) -> int:
    return _op_r(IMM, 5, 0x20, rd, rs1, shamt)


def add(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 0, 0x00, rd, rs1, rs2)


def sub(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 0, 0x20, rd, rs1, rs2)


def sll(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 1, 0x00, rd, rs1, rs2)


def slt(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 2, 0x00, rd, rs1, rs2)


def sltu(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 3, 0x00, rd, rs1, rs2)


def xor(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 4, 0x00, rd, rs1, rs2)


def srl(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 5, 0x00, rd, rs1, rs2)


def sra(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 5, 0x20, rd, rs1, rs2)


def or_op(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 6, 0x00, rd, rs1, rs2)


def and_op(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 7, 0x00, rd, rs1, rs2)


def mul(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 0, 0x01, rd, rs1, rs2)


def mulh(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 1, 0x01, rd, rs1, rs2)


def mulhsu(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 2, 0x01, rd, rs1, rs2)


def mulhu(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 3, 0x01, rd, rs1, rs2)


def div(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 4, 0x01, rd, rs1, rs2)


def divu(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 5, 0x01, rd, rs1, rs2)


def rem(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 6, 0x01, rd, rs1, rs2)


def remu(rd: int, rs1: int, rs2: int) -> int:
    return _op_r(OP, 7, 0x01, rd, rs1, rs2)
