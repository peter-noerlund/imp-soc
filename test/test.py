# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, First, Timer, RisingEdge


async def memory_device(dut, ss_n, memory: bytearray):
    while True:
        await FallingEdge(ss_n)
        assert dut.spi_sck.value == 0

        command = 0

        for i in range(8):
            await First(RisingEdge(dut.spi_sck), RisingEdge(ss_n))
            if ss_n.value != 0:
                break;

            assert dut.spi_sio_oe.value == 0x1
            command = (command << 1) | int(dut.spi_sio_out[0].value)

        if ss_n.value != 0:
            continue

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


@cocotb.test()
async def test_project(dut):
    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    with open("app/test.bin", "rb") as f:
        flash = f.read()
    cocotb.start_soon(memory_device(dut, dut.spi_flash_ss_n, flash))

    psram = bytearray(8 * 1024 * 1024)
    cocotb.start_soon(memory_device(dut, dut.spi_psram_ss_n, psram))

    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 7000000)
