`default_nettype none

module pico_ice_top
    (
        input wire ICE_CLK,

        output wire LED_R,
        output wire LED_G,
        output wire LED_B,

        output wire [7:0] ICE_PMOD0,
        input wire [7:0] ICE_PMOD1,
        inout wire [7:0] ICE_PMOD2,

        input wire SW2
    );

    localparam [0:0] ENABLE_TIMER_DEVICE = 1;
    localparam [0:0] ENABLE_INPUT_DEVICE = 1;
    localparam [0:0] ENABLE_AUDIO_DEVICE = 1;
    localparam [0:0] ENABLE_VGA_DEVICE = 1;
    localparam [0:0] ENABLE_RAW_INPUT = 1;
    localparam int GAMEPAD_COUNT = 2;
    
    // ICE_PMOD0 is used for VGA PMOD
    // ICE_PMOD1 is used for SNES PMOD
    // ICE_PMOD2 is used for QSPI and optionally Audio PMOD

    wire clk;
    wire clk_locked;
    bit rst;
    bit [3:0] rst_counter;

    // ICE_PMOD2
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

    // VGA
    wire vga_vsync;
    wire vga_hsync;
    wire [1:0] vga_red;
    wire [1:0] vga_green;
    wire [1:0] vga_blue;

    // VGA Buffer
    bit vga_vsync_buf;
    bit vga_hsync_buf;
    bit [1:0] vga_red_buf;
    bit [1:0] vga_green_buf;
    bit [1:0] vga_blue_buf;

    assign ICE_PMOD0 = {
        vga_hsync_buf, vga_blue_buf[0], vga_green_buf[0], vga_red_buf[0],
        vga_vsync_buf, vga_blue_buf[1], vga_green_buf[1], vga_red_buf[1]
    };

    // LEDs
    assign LED_R = 1'b1;
    assign LED_G = 1'b0;
    assign LED_B = 1'b1;

    // SPI/Audio
    assign pmod2_oe[0] = 1'b1;      // CS0
    assign pmod2_oe[3] = 1'b1;      // SCK
    assign pmod2_oe[7:6] = 2'b11;   // CS1 + CS2/Audio/UART

    assign spi_sck = pmod2_out[3];
    assign spi_sio_in = {pmod2_in[5:4], pmod2_in[2:1]};
    assign spi_sio_out = {pmod2_out[5:4], pmod2_out[2:1]};
    assign spi_sio_oe = {pmod2_oe[5:4], pmod2_oe[2:1]};
    assign spi_flash_ss_n = pmod2_out[0];
    assign spi_psram_ss_n = pmod2_out[6];

    initial begin
        rst = 1'b1;
        rst_counter = 4'd0;
    end

    always_ff @ (posedge clk) begin
        if (!SW2 || !clk_locked) begin
            rst <= 1'b1;
            rst_counter <= 4'd0;
        end else if (rst) begin
            if (rst_counter == 4'd15) begin
                rst <= 1'b0;
            end else begin
                rst_counter <= rst_counter + 4'd1;
            end
        end
    end

    always_ff @ (posedge clk) begin
        vga_vsync_buf <= vga_vsync;
        vga_hsync_buf <= vga_hsync;
        vga_red_buf <= vga_red;
        vga_green_buf <= vga_green;
        vga_blue_buf <= vga_blue;
    end

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

        .input_pmod(ICE_PMOD1),
        .audio_out(pmod2_out[7])
    );
endmodule
