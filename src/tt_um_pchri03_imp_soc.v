`default_nettype none

/* verilator lint_off UNUSEDSIGNAL */
module tt_um_pchri03_imp_soc
    #(
        parameter [0:0] ENABLE_TIMER_DEVICE=1,
        parameter [0:0] ENABLE_INPUT_DEVICE=1,
        parameter [0:0] ENABLE_AUDIO_DEVICE=1,
        parameter [0:0] ENABLE_VGA_DEVICE=1,
        parameter [0:0] ENABLE_RAW_INPUT=1,
        parameter [1:0] GAMEPAD_COUNT=2
    )
    (
        input wire clk,
        input wire rst_n,
        input wire ena,
        input wire [7:0] ui_in,
        output wire [7:0] uo_out,
        input wire [7:0] uio_in,
        output wire [7:0] uio_out,
        output wire [7:0] uio_oe
    );

    assign uio_oe[0] = 1'b1;        // CS
    assign uio_oe[3] = 1'b1;        // SCK
    assign uio_oe[7:6] = 2'b11;     // CS2 + CS3

    soc #(
        .ENABLE_TIMER_DEVICE(ENABLE_TIMER_DEVICE),
        .ENABLE_INPUT_DEVICE(ENABLE_INPUT_DEVICE),
        .ENABLE_AUDIO_DEVICE(ENABLE_AUDIO_DEVICE),
        .ENABLE_VGA_DEVICE(ENABLE_VGA_DEVICE),
        .ENABLE_RAW_INPUT(ENABLE_RAW_INPUT),
        .GAMEPAD_COUNT(GAMEPAD_COUNT)
    ) soc(
        .clk(clk),
        .rst(!rst_n),

        .vga_red({uo_out[0], uo_out[4]}),
        .vga_green({uo_out[1], uo_out[5]}),
        .vga_blue({uo_out[2], uo_out[6]}),
        .vga_vsync(uo_out[3]),
        .vga_hsync(uo_out[7]),

        .spi_sck(uio_out[3]),
        .spi_sio_in({uio_in[5:4], uio_in[2:1]}),
        .spi_sio_out({uio_out[5:4], uio_out[2:1]}),
        .spi_sio_oe({uio_oe[5:4], uio_oe[2:1]}),
        .spi_flash_ss_n(uio_out[0]),
        .spi_psram_ss_n(uio_out[6]),

        .input_pmod(ui_in),
        .audio_out(uio_out[7])
    );

    wire _unused = ena;
endmodule
/* verilator lint_on UNUSEDSIGNAL */
