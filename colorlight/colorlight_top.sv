`default_nettype none

module colorlight_top
    (
        input wire clk25,
        
        output wire LED,
        
        output wire [7:0] P3_PMOD1,
        inout wire [7:0] P3_PMOD2,
        input wire [7:0] P2_PMOD1
    );

    localparam int ENABLE_TIMER_DEVICE = 1;
    localparam int ENABLE_INPUT_DEVICE = 1;
    localparam int ENABLE_AUDIO_DEVICE = 1;
    localparam int ENABLE_VGA_DEVICE = 1;
    localparam int ENABLE_RAW_INPUT = 1;
    localparam int GAMEPAD_COUNT = 2;
    localparam int ENABLE_4BIT = 1;
    localparam int ENABLE_COMPRESSED = 0;

    wire clk;
    wire clk_locked;
    wire rst;

    wire vga_vsync;
    wire vga_hsync;
    wire [1:0] vga_red;
    wire [1:0] vga_green;
    wire [1:0] vga_blue;

    wire [7:0] p3_pmod2_in;
    wire [7:0] p3_pmod2_oe;
    wire [7:0] p3_pmod2_out;

    // SPI
    wire spi_sck;
    wire [3:0] spi_sio_out;
    wire [3:0] spi_sio_oe;
    wire [3:0] spi_sio_in;
    wire spi_flash_ss_n;
    wire spi_psram_ss_n;

    assign rst = ~clk_locked;

    assign p3_pmod2_oe[0] = 1'b1;
    assign p3_pmod2_oe[3] = 1'b1;
    assign p3_pmod2_oe[7:6] = 2'b11;

    assign P3_PMOD1 = {
        vga_hsync, vga_blue[0], vga_green[0], vga_red[0],
        vga_vsync, vga_blue[1], vga_green[1], vga_red[1]
    };

    assign spi_sck = p3_pmod2_out[3];
    assign spi_sio_in = {p3_pmod2_in[5:4], p3_pmod2_in[2:1]};
    assign spi_sio_out = {p3_pmod2_out[5:4], p3_pmod2_out[2:1]};
    assign spi_sio_oe = {p3_pmod2_oe[5:4], p3_pmod2_oe[2:1]};
    assign spi_flash_ss_n = p3_pmod2_out[0];
    assign spi_psram_ss_n = p3_pmod2_out[6];

    assign LED = rst;

    pll pll(
        .clkin(clk25),
        .clkout0(clk),
        .locked(clk_locked)
    );

    BB bb[7:0] (
        .B(P3_PMOD2),
        .O(p3_pmod2_in),
        .T(p3_pmod2_oe),
        .I(p3_pmod2_out)
    );

    soc #(
        .ENABLE_TIMER_DEVICE(ENABLE_TIMER_DEVICE),
        .ENABLE_INPUT_DEVICE(ENABLE_INPUT_DEVICE),
        .ENABLE_AUDIO_DEVICE(ENABLE_AUDIO_DEVICE),
        .ENABLE_VGA_DEVICE(ENABLE_VGA_DEVICE),
        .ENABLE_RAW_INPUT(ENABLE_RAW_INPUT),
        .GAMEPAD_COUNT(GAMEPAD_COUNT)
    ) soc(
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
        .audio_out(p3_pmod2_out[7])
    );
endmodule

