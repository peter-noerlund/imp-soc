`default_nettype none

module vga_renderer
    #(
        parameter int CHUNK_COUNT=16,
        parameter int LINE_HEIGHT=8
    )
    (
        input wire clk,
        input wire rst,

        input wire vgaconfig_enabled,

        output wire vgactrl_read_req,
        output wire vgactrl_reset_req,
        input wire [CHUNK_COUNT * 28 - 1 : 0] vgactrl_memory,

        //! @virtualbus VGA @dir output VGA
        output wire vga_hsync,                      //! VGA horizontal sync
        output wire vga_vsync,                      //! VGA vertical sync
        output wire [1:0] vga_red,                  //! VGA red
        output wire [1:0] vga_green,                //! VGA green
        output wire [1:0] vga_blue                  //! VGA blue
        //! @end
    );


    localparam int HPIXELS = 1024;
    localparam int VPIXELS = 768;
    localparam int HPOS_WIDTH = 11;     // 1338 actual horizontal pixels
    localparam int VPOS_WIDTH = 10;
    localparam int PIXEL_COUNT = CHUNK_COUNT * 8;
    localparam int SUBPIXEL_WIDTH = HPIXELS / PIXEL_COUNT;
    localparam int SUBPIXEL_IDX_WIDTH = $clog2(SUBPIXEL_WIDTH);
    localparam int CHUNK_IDX_WIDTH = $clog2(CHUNK_COUNT);
    localparam int PIXEL_IDX_WIDTH = 3;
    localparam int SUBLINE_IDX_WIDTH = $clog2(LINE_HEIGHT);
    localparam int SUBLINE_MAX = LINE_HEIGHT - 1;

    wire [HPOS_WIDTH - 1 : 0] h_pos;
    wire [VPOS_WIDTH - 1 : 0] v_pos;
    wire blank;
    wire h_sync;
    wire v_sync;

    bit active;

    bit [27:0] chunk;       // Current chunk
    wire [5:0] color1;      // Color1 from chunk
    wire [5:0] color2;      // Color2 from chunk
    wire [5:0] color3;      // Interpolated color3
    wire [5:0] black;       // The color black
    wire [15:0] pixels;     // The pixels
    wire [1:0] pixel;       // The current pixel
    wire [5:0] pixel_color; // The color of the current pixel
    wire [1:0] red;         // Red part of current pixel
    wire [1:0] green;       // Green part of current pixel
    wire [1:0] blue;        // Blue part of current pixel

    wire [1:0] red1;
    wire [1:0] green1;
    wire [1:0] blue1;
    wire [1:0] red2;
    wire [1:0] green2;
    wire [1:0] blue2;
    wire [1:0] red3;
    wire [1:0] green3;
    wire [1:0] blue3;
    wire [2:0] sum_red;
    wire [2:0] sum_green;
    wire [2:0] sum_blue;

    wire [CHUNK_IDX_WIDTH - 1 : 0] chunk_idx;       // Index of current chunk
    wire [PIXEL_IDX_WIDTH - 1 : 0] pixel_idx;       // Index of current pixel
    wire [SUBPIXEL_IDX_WIDTH - 1 : 0] subpixel_idx; // Index of current subpixel
    wire [SUBLINE_IDX_WIDTH - 1 : 0] subline_idx;   // Index within current line

    int i;

    assign red1 = color1[5:4];
    assign green1 = color1[3:2];
    assign blue1 = color1[1:0];
    assign red2 = color2[5:4];
    assign green2 = color2[3:2];
    assign blue2 = color2[1:0];
    assign sum_red = 3'(red1) + 3'(red2);
    assign sum_green = 3'(green1) + 3'(green2);
    assign sum_blue = 3'(blue1) + 3'(blue2);
    assign red3 = sum_red[2:1];
    assign green3 = sum_green[2:1];
    assign blue3 = sum_blue[2:1];
    assign color3 = {red3, green3, blue3};
    
    // h_pos implicitly stores at lot of state.
    // 
    // For 1024x768, it looks like this (C=chunk, G=group, P=pixel, S=subpixel):
    //
    //  1
    //  0 9 8 7 6 5 4 3 2 1 0
    // +-+-+-+-+-+-+-+-+-+-+-+
    // | |   C   |  P  |  S  |
    // +-+-+-+-+-+-+-+-+-+-+-+
    //
    // For 640x480 (512x384) it looks like this:
    //
    //  9 8 7 6 5 4 3 2 1 0
    // +-+-+-+-+-+-+-+-+-+-+
    // | |   C   |  P  | S |
    // +-+-+-+-+-+-+-+-+-+-+

    assign subpixel_idx = h_pos[SUBPIXEL_IDX_WIDTH - 1 : 0];
    assign pixel_idx = h_pos[PIXEL_IDX_WIDTH + SUBPIXEL_IDX_WIDTH - 1 : SUBPIXEL_IDX_WIDTH];
    assign chunk_idx = h_pos[CHUNK_IDX_WIDTH + PIXEL_IDX_WIDTH + SUBPIXEL_IDX_WIDTH - 1 : PIXEL_IDX_WIDTH + SUBPIXEL_IDX_WIDTH];
    assign subline_idx = v_pos[SUBLINE_IDX_WIDTH - 1 : 0];

    assign black = 6'b000000;
    assign color2 = chunk[27:22];
    assign color1 = chunk[21:16];
    assign pixels = chunk[15:0];

    assign pixel = pixels[pixel_idx * 2 + 1 -: 2];

    assign pixel_color =
        (pixel == 2'd1) ? color1 :
        (pixel == 2'd2) ? color2 :
        (pixel == 2'd3) ? color3 :
        black;

    assign red = pixel_color[5:4];
    assign green = pixel_color[3:2];
    assign blue = pixel_color[1:0];

    assign vga_red = blank ? 2'b00 : red;
    assign vga_green = blank ? 2'b00 : green;
    assign vga_blue = blank ? 2'b00 : blue;
    assign vga_hsync = h_sync;
    assign vga_vsync = v_sync;
    assign vgactrl_read_req = h_pos == HPOS_WIDTH'(HPIXELS - 1) && subpixel_idx == SUBPIXEL_IDX_WIDTH'(SUBPIXEL_WIDTH - 1) && subline_idx == SUBLINE_IDX_WIDTH'(SUBLINE_MAX) && active && vgaconfig_enabled;
    assign vgactrl_reset_req = h_pos == HPOS_WIDTH'(HPIXELS - 1) && subpixel_idx == SUBPIXEL_IDX_WIDTH'(SUBPIXEL_WIDTH - 1) && v_pos == VPOS_WIDTH'(0);

    always_comb begin
        chunk = 28'h0000000;
        for (i = 0; i != CHUNK_COUNT; i++) begin
            if (chunk_idx == CHUNK_IDX_WIDTH'(i)) begin
                chunk = vgactrl_memory[i * 28 + 27 -: 28];
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            active <= 1'b1;
        end else begin
            if (v_pos == VPOS_WIDTH'(VPIXELS + 1)) begin
                active <= 1'b0; // TODO - Do not fetch after last line
            end else if (v_pos == VPOS_WIDTH'(0)) begin
                active <= 1'b1; // TODO - Wait until line -1
            end
        end
    end

    vga_timing timing(
        .clk(clk),
        .rst(rst),
        .vga_hpos(h_pos),
        .vga_vpos(v_pos),
        .vga_hsync(h_sync),
        .vga_vsync(v_sync),
        .vga_blank(blank)
    );

    wire _unused = &{sum_red[0], sum_green[0], sum_blue[0]};
endmodule
