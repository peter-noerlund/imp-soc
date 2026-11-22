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


async def vga_device(dut, frames: list):
    last_clk = 0
    last_vsync = 0
    last_hsync = 0
    vpos = 0
    hpos = 0

    frame = []

    await RisingEdge(dut.clk)

    while True:
        await ClockCycles(dut.clk, 1)
        
        if dut.rst_n.value == 0:
            last_vsync = 0
            last_hsync = 0
            vpos = 0
            hpos = 0
            continue

        hpos = (hpos + 1) % (1024 + 24 + 136 + 160)

        if last_hsync == 1 and dut.vga_hsync.value == 0:
            print("HSYNC");
            hpos = 1024 + 24
            vpos = (vpos + 1) % (786 + 3 + 6 + 29)

        if last_vsync == 1 and dut.vga_vsync.value == 0:
            print("Frame")
            vpos = 768 + 3

            frames.append(frame)
            frame = []

        if hpos < 1024 and vpos < 768:
            pixel = (int(dut.vga_red.value) << 4) | (int(dut.vga_green.value) << 2) | int(dut.vga_blue.value)
            frame.append(pixel)

        last_vsync = int(dut.vga_vsync.value)
        last_hsync = int(dut.vga_hsync.value)


@cocotb.test()
async def test_project(dut):
    return

    clock = Clock(dut.clk, 15.384, unit="ns")
    cocotb.start_soon(clock.start())

    with open("app/test.bin", "rb") as f:
        flash = f.read()
    cocotb.start_soon(memory_device(dut, dut.spi_flash_ss_n, flash))

    psram = bytearray(8 * 1024 * 1024)
    cocotb.start_soon(memory_device(dut, dut.spi_psram_ss_n, psram))

    frames = []

    cocotb.start_soon(vga_device(dut, frames))

    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 10000000)

    red_frame_idx = -1
    green_frame_idx = -1
    blue_frame_idx = -1

    print(frames)

    for i in range(len(frames)):
        frame = frames[i]
        if len(frame) < 1024 * 768:
            continue

        pixel = frame[0]
        valid = True
        for i in range(1, 1024 * 768):
            if frame[i] != pixel:
                valid = False
                break

        if not valid:
            continue

        if pixel == 0x30 and red_frame_idx == -1:
            red_frame_idx = i
        elif pixel == 0x0C and green_frame_idx == -1:
            green_frame_idx = i
        elif pixel == 0x03 and blue_frame_idx == -1:
            blue_frame_idx = i

    assert red_frame_idx != -1, "Red frame was presented"
    assert green_frame_idx > red_frame_idx, "Green frame came after red frame"
    assert blue_frame_idx > green_frame_idx, "Blue frame came efter green frame"

