`default_nettype none

/* verilator lint_off UNUSEDSIGNAL */
module tt_um_pchri03_imp_soc
    (
        input wire [7:0] ui_in,
        output wire [7:0] uo_out,
        input wire [7:0] uio_in,
        output wire [7:0] uio_out,
        output wire [7:0] uio_oe,
        input wire ena,
        input wire clk,
        input wire rst_n
    );

    assign uio_oe[0] = 1'b1;        // CS
    assign uio_oe[3] = 1'b1;        // SCK
    assign uio_oe[7:6] = 2'b11;     // CS2 + CS3

    soc #(.ENABLE_UART(0)) soc(
        .clk(clk),
        .rst(!rst_n),

        .spi_sck(uio_out[3]),
        .spi_sio_in({uio_in[5:4], uio_in[2:1]}),
        .spi_sio_out({uio_out[5:4], uio_out[2:1]}),
        .spi_sio_oe({uio_oe[5:4], uio_oe[2:1]}),
        .spi_flash_ss_n(uio_out[0]),
        .spi_psram_ss_n(uio_out[6]),
        
        .uart_tx(uio_out[7]),

        .vga_red({uo_out[0], uo_out[4]}),
        .vga_green({uo_out[1], uo_out[5]}),
        .vga_blue({uo_out[2], uo_out[6]}),
        .vga_vsync(uo_out[3]),
        .vga_hsync(uo_out[7])
    );
endmodule
/* verilator lint_on UNUSEDSIGNAL */
