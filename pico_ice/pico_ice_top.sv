`default_nettype none

module pico_ice_top
    (
        input wire ICE_CLK,

        output wire LED_R,
        output wire LED_G,
        output wire LED_B,

        output wire [7:0] ICE_PMOD0,
        //input wire [7:0] ICE_PMOD1,
        inout wire [7:0] ICE_PMOD2
    );

    // ICE_PMOD0 is used for VGA PMOD
    // ICE_PMOD1 is used for SNES PMOD
    // ICE_PMOD2 is used for QSPI and optionally Audio PMOD

    wire clk;
    wire clk_locked;
    wire rst;

    wire uart_tx;

    // ICE_PMOD0
    wire [7:0] pmod2_in;
    wire [7:0] pmod2_oe;
    wire [7:0] pmod2_out;

    // SPI
    wire spi_sck;
    wire [3:0] spi_sio_out;
    wire [3:0] spi_sio_oe;
    wire [3:0] spi_sio_in;
    wire spi_flash_ss_n;
    wire spi_psram_ss_n;

    assign LED_R = 1'b1;
    assign LED_G = ~clk_locked;
    assign LED_B = 1'b1;

    assign rst = ~clk_locked;

    assign pmod2_oe[0] = 1'b1;      // CS0
    assign pmod2_oe[3] = 1'b1;      // SCK
    assign pmod2_oe[7:6] = 2'b11;   // CS1 + CS2/Audio/UART
    assign pmod2_out[7] = 1'b1;

    assign spi_sck = pmod2_out[3];
    assign spi_sio_in = {pmod2_in[5:4], pmod2_in[2:1]};
    assign spi_sio_out = {pmod2_out[5:4], pmod2_out[2:1]};
    assign spi_sio_oe = {pmod2_oe[5:4], pmod2_oe[2:1]};
    assign spi_flash_ss_n = pmod2_out[0];
    assign spi_psram_ss_n = pmod2_out[6];

    pll pll(
        .clock_in(ICE_CLK),
        .clock_out(clk),
        .locked(clk_locked)
    );

    SB_IO #(
        .PIN_TYPE(6'b1010_01)
    ) pmod2_pin[7:0] (
        .PACKAGE_PIN(ICE_PMOD2),
        .OUTPUT_ENABLE(pmod2_oe),
        .D_OUT_0(pmod2_out),
        .D_IN_0(pmod2_in)
    );

    soc #(.ENABLE_UART(1)) soc(
        .clk(clk),
        .rst(rst),

        .uart_tx(uart_tx),

        .spi_sck(spi_sck),
        .spi_sio_out(spi_sio_out),
        .spi_sio_oe(spi_sio_oe),
        .spi_sio_in(spi_sio_in),
        .spi_flash_ss_n(spi_flash_ss_n),
        .spi_psram_ss_n(spi_psram_ss_n),

        .vga_red({ICE_PMOD0[0], ICE_PMOD0[4]}),
        .vga_green({ICE_PMOD0[1], ICE_PMOD0[5]}),
        .vga_blue({ICE_PMOD0[2], ICE_PMOD0[6]}),
        .vga_vsync(ICE_PMOD0[3]),
        .vga_hsync(ICE_PMOD0[7])
    );
endmodule