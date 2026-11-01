`default_nettype none

module vga_renderer
    #(
        parameter int CHUNK_COUNT=10
    )
    (
        input wire clk,
        input wire rst,

        input wire vgaconfig_enabled,

        output wire vgactrl_read_req,
        input wire [CHUNK_COUNT * 24 - 1 : 0] vgactrl_memory,

        //! @virtualbus VGA @dir output VGA
        output wire vga_hsync,                      //! VGA horizontal sync
        output wire vga_vsync,                      //! VGA vertical sync
        output wire [1:0] vga_red,                  //! VGA red
        output wire [1:0] vga_green,                //! VGA green
        output wire [1:0] vga_blue                  //! VGA blue
        //! @end
    );

    localparam int CHUNK_IDX_WIDTH = $clog2(CHUNK_COUNT);

    localparam [2:0] PIXELS_BB = 3'b000;
    localparam [2:0] PIXELS_B1 = 3'b001;
    localparam [2:0] PIXELS_B2 = 3'b010;
    localparam [2:0] PIXELS_1B = 3'b011;
    localparam [2:0] PIXELS_11 = 3'b100;
    localparam [2:0] PIXELS_12 = 3'b101;
    localparam [2:0] PIXELS_2B = 3'b110;
    // PIXELS_21 is not allowed
    localparam [2:0] PIXELS_22 = 3'b111;

    wire [1:0] red;
    wire [1:0] green;
    wire [1:0] blue;
    wire [5:0] pixel;
`ifdef PICO_ICE
    wire [9:0] vga_hpos;
`else
    wire [10:0] vga_hpos;
`endif
    wire [9:0] vga_vpos;
    wire vga_blank;
    wire [CHUNK_IDX_WIDTH - 1 : 0] chunk_idx;
    wire [2:0] pixel_idx;
    bit active;
    wire [5:0] color1;
    wire [5:0] color2;
    bit [5:0] pixel0;
    bit [5:0] pixel1;
    wire [2:0] pixel_group;
    wire [1:0] pixel_group_idx;
    wire pixel_group_subpixel_idx;
    bit [23:0] chunk;

    int i;
    
    assign vga_red = vga_blank ? 2'b00 : red;
    assign vga_green = vga_blank ? 2'b00 : green;
    assign vga_blue = vga_blank ? 2'b00 : blue;

    // Each pixel is repeated 4 cycles
    assign pixel_idx = vga_hpos[4:2];
    assign pixel_group_idx = pixel_idx[2:1];
    assign pixel_group_subpixel_idx = pixel_idx[0];

    // Each chunk represents 8 pixels
    assign chunk_idx = vga_hpos[CHUNK_IDX_WIDTH + 5 - 1 : 5];

    assign color1 = chunk[23:18];
    assign color2 = chunk[17:12];
    assign pixel_group = chunk[(3 - pixel_group_idx) * 3 + 2 -: 3];

    assign pixel = pixel_group_subpixel_idx ? pixel1 : pixel0;
    assign red = pixel[5:4];
    assign green = pixel[3:2];
    assign blue = pixel[1:0];

    assign vgactrl_read_req = vga_hpos == 11'd639 && vga_vpos[1:0] == 2'b11 && active && vgaconfig_enabled;

    always_comb begin
        case (pixel_group)
            PIXELS_BB: pixel0 = 6'b000000;
            PIXELS_B1: pixel0 = color1;
            PIXELS_B2: pixel0 = color2;
            PIXELS_1B: pixel0 = 6'b000000;
            PIXELS_11: pixel0 = color1;
            PIXELS_12: pixel0 = color2;
            PIXELS_2B: pixel0 = 6'b000000;
            PIXELS_22: pixel0 = color2;
        endcase
    end

    always_comb begin
        case (pixel_group)
            PIXELS_BB: pixel1 = 6'b000000;
            PIXELS_B1: pixel1 = 6'b000000;
            PIXELS_B2: pixel1 = 6'b000000;
            PIXELS_1B: pixel1 = color1;
            PIXELS_11: pixel1 = color1;
            PIXELS_12: pixel1 = color1;
            PIXELS_2B: pixel1 = color2;
            PIXELS_22: pixel1 = color2;
        endcase
    end

    always_comb begin
        chunk = 24'h000000;
        for (i = 0; i != CHUNK_COUNT; i++) begin
            if (chunk_idx == CHUNK_IDX_WIDTH'(i)) begin
                chunk = {vgactrl_memory[i * 24 + 7 -: 8], vgactrl_memory[i * 24 + 15 -: 8], vgactrl_memory[i * 24 + 23 -: 8]};
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            active <= 1'b1;
        end else begin
            if (vga_vpos == 10'd401) begin
                active <= 1'b0; // TODO - Do not fetch after last line
            end
            if (vga_vpos == 10'd0) begin
                active <= 1'b1; // TODO - Wait until line -1
            end
        end
    end

`ifdef PICO_ICE
    // PICO-ICE runs at 25.075 MHz and outputs VGA 640x480 at 60Hz
    vga_timing #(
        .H_PIXELS(640),
        .V_PIXELS(480),
        .H_RIGHT_BORDER(8),
        .H_FRONT_PORCH(8),
        .H_SYNC_TIME(96),
        .H_BACK_PORCH(40),
        .H_LEFT_BORDER(8),
        .V_BOTTOM_BORDER(8),
        .V_FRONT_PORCH(2),
        .V_SYNC_TIME(25),
        .V_BACK_PORCH(25),
        .V_TOP_BORDER(8),
        .H_SYNC_POLARITY(0),
        .V_SYNC_POLARITY(0)
    ) timing (
        .clk(clk),
        .rst(rst),
        .vga_hpos(vga_hpos),
        .vga_vpos(vga_vpos),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_blank(vga_blank)
    );
`else
    // ASIC runs at 65 MHz and outputs VESA 1024x768 at 60Hz, letter boxed to 640x480
    vga_timing #(
        .H_LEFT_BORDER(192), .H_PIXELS(640), .H_RIGHT_BORDER(192),
        .V_TOP_BORDER(144), .V_PIXELS(480), .V_BOTTOM_BORDER(144)
    ) timing(
        .clk(clk),
        .rst(rst),
        .vga_hpos(vga_hpos),
        .vga_vpos(vga_vpos),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_blank(vga_blank)
    );
`endif
endmodule
