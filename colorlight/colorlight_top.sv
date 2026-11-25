`default_nettype none

module colorlight_top
    (
        input wire clk25,
        
        output wire LED,
        
        output wire [7:0] P3_PMOD1,
        inout wire [7:0] P3_PMOD2,
        input wire [7:0] P2_PMOD1
    );

    wire clk;
    wire clk_locked;
    wire rst;

    // VGA
    wire vga_vsync;
    wire vga_hsync;
    wire [1:0] vga_red;
    wire [1:0] vga_green;
    wire [1:0] vga_blue;

    // SPI
    wire spi_sck;
    wire [3:0] spi_sio_out;
    wire [3:0] spi_sio_oe;
    wire [3:0] spi_sio_in;
    wire spi_flash_ss_n;
    wire spi_psram_ss_n;

    // Audio
    wire audio_out;

    // Bidirectional PMOD
    wire [7:0] p3_pmod2_in;
    wire [7:0] p3_pmod2_oe;
    wire [7:0] p3_pmod2_out;

    // VGA
    assign P3_PMOD1 = {
        vga_hsync, vga_blue[0], vga_green[0], vga_red[0],
        vga_vsync, vga_blue[1], vga_green[1], vga_red[1]
    };

    // SPI + Audio
    assign p3_pmod2_oe = {2'b11, spi_sio_oe[3:2], 1'b1, spi_sio_oe[1:0], 1'b1};
    assign p3_pmod2_out = {
        audio_out,
        spi_psram_ss_n,
        spi_sio_out[3:2],
        spi_sck,
        spi_sio_out[1:0],
        spi_flash_ss_n
    };
    assign spi_sio_in = {p3_pmod2_in[5:4], p3_pmod2_in[2:1]};

    assign LED = rst;

    reset_handler reset_handler(
        .clk(clk),
        .rst_in(clk_locked),
        .rst_out(rst)
    );

    pll pll(
        .clkin(clk25),
        .clkout0(clk),
        .locked(clk_locked)
    );

    BB bb[7:0] (
        .B(P3_PMOD2),
        .O(p3_pmod2_in),
        .T(~p3_pmod2_oe),
        .I(p3_pmod2_out)
    );

    soc #(.DEBUG(0)) soc(
        .clk(clk),
        .rst(rst),

        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue),
        .vga_vsync(vga_vsync),
        .vga_hsync(vga_hsync),

        .spi_sck(spi_sck),
        .spi_sio_out(spi_sio_out),
        .spi_sio_oe(spi_sio_oe),
        .spi_sio_in(spi_sio_in),
        .spi_flash_ss_n(spi_flash_ss_n),
        .spi_psram_ss_n(spi_psram_ss_n),

        .input_pmod(P2_PMOD1),
        .audio_out(audio_out)
    );

    wire _unused = &{p3_pmod2_in[7:6], p3_pmod2_in[3:2], p3_pmod2_in[0]};
endmodule

