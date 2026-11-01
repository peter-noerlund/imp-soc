`default_nettype none

module video_renderer
    #(
        parameter int ADDR_WIDTH=32
    )
    (
        input wire clk,
        input wire rst,

        //! @virtualbus CONFIG @dir input Config bus
        input wire config_enabled,
        input wire [ADDR_WIDTH - 1 : 0] config_addr,
        //! @end

        //! @virtualbus WB @dir output Wishbone bus
        output wire wb_cyc,                         //! Wishbone CYC_O
        output wire wb_stb,                         //! Wishbone STB_O
        output wire [ADDR_WIDTH - 1 : 0] wb_adr,    //! Wishbone ADR_O
        output wire wb_we,                          //! Wishbone WE_O
        output wire [3:0] wb_sel,                   //! Wishbone SEL_O
        output wire [2:0] wb_cti,                   //! Wishbone CTI_O
        output wire [1:0] wb_bte,                   //! Wishbone BTE_O
        output wire [31:0] wb_dat,                  //! Wishbone DAT_O
        input wire wb_ack,                          //! Wishbone ACK_I
        input wire wb_rty,                          //! Wishbone RTY_I
        input wire wb_err,                          //! Wishbone ERR_I
        input wire [31:0] wb_rdt,                   //! Wishbone DAT_I
        //! @end

        //! @virtualbus VGA @dir output VGA
        output wire vga_hsync,                      //! VGA horizontal sync
        output wire vga_vsync,                      //! VGA vertical sync
        output wire [1:0] vga_red,                  //! VGA red
        output wire [1:0] vga_green,                //! VGA green
        output wire [1:0] vga_blue                  //! VGA blue
        //! @end
    );

    /*
        Accoding to the VESA Monitor Timing Standard, 640x480@60Hz has the following config:

        Horizontal pixels: 640
        Vertical pixels: 480
        Pixel clock: 25.175 MHz
        Horizontal sync polarity: negative
        Vertical sync polarity: negative
        
        Horizontal right border: 8 pixels
        Horizontal front porch: 8 pixels
        Horizontal sync time: 96 pixels
        Horizontal back porch: 40 pixels
        Horizontal left border: 8 pixels
        Horizontal blank time: 144 pixels (160 with border)

        Vertical bottom border: 8 lines
        Vertical front porch: 2 lines
        Vertical sync time: 2 lines
        Vertical back porch: 25 lines
        Vertical top border: 8 lines
        Vertical blank time: 29 lines (45 with border)

        Chip frequency is 50.350MHz, so the counters counts twice per pixel clock.

        Virtual resolution is 80x50, stretched to 640x400, but the VGA output is 640x480, so we offset everything 40 lines.

        Both the horizontal and vertical counters start when the pixels start, so that means the timing is a bit different vertically:

        Horizontal:
        0:      Pixels
        1280:   Right border
        1296:   Front porch
        1312:   Sync
        1504:   Back porch
        1584:   Left border
        1600:   (end)

        Vertical:
        0:      Pixels
        400:    Bottom letter box
        440:    Bottom border
        448:    Front porch
        450:    Sync
        452:    Back porch
        477:    Top border
        485:    Top letter box
        525:    (end)

        Notice the pattern in the counters:

         1
         0 9 8 7 6 5 4 3 2 1 0
        +-+-+-+-+-+-+-+-+-+-+-+
        |         |   |     | |
        |         |   |     +-+-- VGA/Clock difference
        |         |   |     |
        |         |   +-----+---- Sub pixel position
        |         |   |
        |         +---+---------- Sub word pixel
        |         |
        +---------+-------------- Word
    */

    /*
    TODO - We need a simpler design.

    Suggested approach is to have 4 or 5 chunks of 96 bits holding 16 pixels

    Fetcher is only active when not blanking
    Chunk 0 is the rendering chunk. Every 8 cycle, it shifts 6 bits (1 pixel)
    Chunk 1 is the loading chunk. At each ack, it shifts 24 bits (4 pixels)
    Chunk 2-4 are memory chunks

    All the chunks are rotated every 16 pixel, so every 256 cycle

    Each flip-flop in chunk 0 will have a mux selecting between:
      - itself
      - the next pixel
      - pixel from chunk 1
    Each flip-flop in chunk 1 will have a mux selecting between:
      - itself
      - the wishbone data
      - the 4th next pixel
      - pixel from chunk 2
    Each flip-flop in chunk 2-4 will have a mux selecting between:
      - itself
      - pixel from the next chunk

    area of sky130_fd_sc_hd__dfxtp_2 is 21.27
    area of sky130_fd_sc_hd__mux2_1 is 11.26
    area of sky130_fd_sc_hd__mux4_2 is 22.51

    area of video_rendrer is currently 18,913 of which 10,996 are flip flops.
    
    This solution is presumable 80 flip flops, 128 mux2, and 16 mux4
    
    */

    localparam CTI_CLASSIC = 3'b000;
    localparam CTI_INCREMENT = 3'b010;
    localparam CTI_END_OF_BURST = 3'b111;

    localparam BTE_LINEAR = 2'b00;

    localparam int CLOCK_RATIO = 2;

    localparam int H_PIXELS = 640;
    localparam int H_RIGHT_BORDER = 8;
    localparam int H_FRONT_PORCH = 8;
    localparam int H_SYNC_TIME = 96;
    localparam int H_BACK_PORCH = 40;
    localparam int H_LEFT_BORDER = 8;

    localparam int V_PIXELS = 400;
    localparam int V_BOTTOM_LETTERBOX = 40;
    localparam int V_BOTTOM_BORDER = 8;
    localparam int V_FRONT_PORCH = 2;
    localparam int V_SYNC_TIME = 2;
    localparam int V_BACK_PORCH = 25;
    localparam int V_TOP_BORDER = 8;
    localparam int V_TOP_LETTERBOX = 40;

    localparam int H_POS_WIDTH = $clog2((H_PIXELS + H_RIGHT_BORDER + H_FRONT_PORCH + H_SYNC_TIME + H_BACK_PORCH + H_LEFT_BORDER) * CLOCK_RATIO);
    localparam int V_POS_WIDTH = $clog2(V_PIXELS + V_BOTTOM_LETTERBOX + V_BOTTOM_BORDER + V_FRONT_PORCH + V_SYNC_TIME + V_BACK_PORCH + V_TOP_BORDER + V_TOP_LETTERBOX);

    bit hsync;
    bit vsync;
    bit hblank;
    bit vblank;

    bit [H_POS_WIDTH - 1 : 0] h_pos;
    bit [V_POS_WIDTH - 1 : 0] v_pos;

    bit [119:0] pixel_buffer_left;
    bit [119:0] pixel_buffer_right;
    bit [6:0] pixel;

    wire blank;
    wire [1:0] red;
    wire [1:0] green;
    wire [1:0] blue;

    wire [H_POS_WIDTH - 1 : 0] h_pos_sync_start;
    wire [H_POS_WIDTH - 1 : 0] h_pos_sync_end;
    wire [H_POS_WIDTH - 1 : 0] h_pos_blank_start;
    wire [H_POS_WIDTH - 1 : 0] h_pos_blank_end;
    wire [H_POS_WIDTH - 1 : 0] h_pos_max;

    wire [V_POS_WIDTH - 1 : 0] v_pos_sync_start;
    wire [V_POS_WIDTH - 1 : 0] v_pos_sync_end;
    wire [V_POS_WIDTH - 1 : 0] v_pos_blank_start;
    wire [V_POS_WIDTH - 1 : 0] v_pos_blank_end;
    wire [V_POS_WIDTH - 1 : 0] v_pos_max;

    wire render_right_buffer;
    wire [4:0] render_word_index_raw;
    wire [4:0] render_word_index_offsettet;
    wire [3:0] render_word_index;
    wire [1:0] render_pixel_index;
    wire [2:0] render_pixel_subindex;
    wire [23:0] render_pixels;
    wire [5:0] render_pixel;

    wire [6:0] render_line_index;
    wire [3:0] render_line_subindex;

    bit cyc;
    bit [4:0] adr_upper;
    bit [2:0] adr_lower;
    wire load_right;
    wire [23:0] wb_pixels;

    wire ack;

    assign blank = hblank | vblank;

    assign ack = wb_ack | wb_rty | wb_err;

    assign vga_hsync = !hsync;
    assign vga_vsync = !vsync;
    assign vga_red = blank ? 2'd0 : red;
    assign vga_green = blank ? 2'd0 : green;
    assign vga_blue = blank ? 2'd0 : blue;

    assign h_pos_blank_start    = H_POS_WIDTH'(H_PIXELS * CLOCK_RATIO - 1);
    assign h_pos_sync_start     = H_POS_WIDTH'((H_PIXELS + H_RIGHT_BORDER + H_FRONT_PORCH) * CLOCK_RATIO - 1);
    assign h_pos_sync_end       = H_POS_WIDTH'((H_PIXELS + H_RIGHT_BORDER + H_FRONT_PORCH + H_SYNC_TIME) * CLOCK_RATIO - 1);
    assign h_pos_blank_end      = H_POS_WIDTH'((H_PIXELS + H_RIGHT_BORDER + H_FRONT_PORCH + H_SYNC_TIME + H_BACK_PORCH + H_LEFT_BORDER) * CLOCK_RATIO - 1);
    assign h_pos_max            = H_POS_WIDTH'((H_PIXELS + H_RIGHT_BORDER + H_FRONT_PORCH + H_SYNC_TIME + H_BACK_PORCH + H_LEFT_BORDER) * CLOCK_RATIO - 1);

    assign v_pos_blank_start    = V_POS_WIDTH'(V_PIXELS - 1);
    assign v_pos_sync_start     = V_POS_WIDTH'(V_PIXELS + V_BOTTOM_LETTERBOX + V_BOTTOM_BORDER + V_FRONT_PORCH - 1);
    assign v_pos_sync_end       = V_POS_WIDTH'(V_PIXELS + V_BOTTOM_LETTERBOX + V_BOTTOM_BORDER + V_FRONT_PORCH + V_SYNC_TIME - 1);
    assign v_pos_blank_end      = V_POS_WIDTH'(V_PIXELS + V_BOTTOM_LETTERBOX + V_BOTTOM_BORDER + V_FRONT_PORCH + V_SYNC_TIME + V_BACK_PORCH + V_TOP_BORDER + V_TOP_LETTERBOX - 1);
    assign v_pos_max            = V_POS_WIDTH'(V_PIXELS + V_BOTTOM_LETTERBOX + V_BOTTOM_BORDER + V_FRONT_PORCH + V_SYNC_TIME + V_BACK_PORCH + V_TOP_BORDER + V_TOP_LETTERBOX - 1);

    assign render_word_index_raw = h_pos[10:6];
    assign render_right_buffer = render_word_index_raw > 5'd9 && render_word_index_raw < 5'd20;
    assign render_word_index_offsettet = render_word_index_raw - 5'd10;
    assign render_word_index = render_right_buffer ? render_word_index_offsettet[3:0] : render_word_index_raw[3:0];
    assign render_pixel_index = h_pos[6:5];
    assign render_pixel_subindex = h_pos[4:1];

    assign render_line_index = v_pos[9:4];
    assign render_line_subindex = v_pos[3:0];

    assign load_right = adr_upper[0];

    assign render_pixels = render_right_buffer ? pixel_buffer_right[23:0] : pixel_buffer_left[23:0];
    assign render_pixel = render_pixels[render_pixel_index * 6 + 5 -: 6];
    assign red = render_pixel[5:4];
    assign green = render_pixel[3:2];
    assign blue = render_pixel[1:0];

    assign wb_cyc = cyc;
    assign wb_stb = cyc;
    assign wb_adr = {config_addr[ADDR_WIDTH - 1 : 10], adr_upper, adr_lower, 2'd00};
    assign wb_we = 1'b0;
    assign wb_sel = 4'b1111;
    assign wb_cti = adr_lower == 3'd4 ? CTI_END_OF_BURST : CTI_INCREMENT;
    assign wb_bte = BTE_LINEAR;
    assign wb_dat = 32'h00000000;


    assign wb_pixels = {
        wb_rdt[31:30], wb_rdt[28:27], wb_rdt[25:23],
        wb_rdt[23:22], wb_rdt[20:19], wb_rdt[17:16],
        wb_rdt[15:14], wb_rdt[12:11], wb_rdt[9:8],
        wb_rdt[7:6], wb_rdt[4:3], wb_rdt[1:0]
    };

    // Horizontal pixel clock
    always_ff @ (posedge clk) begin
        if (rst) begin
            h_pos <= H_POS_WIDTH'(0);
        end else begin
            if (h_pos == h_pos_max) begin
                h_pos <= H_POS_WIDTH'(0);
            end else begin
                h_pos <= h_pos + H_POS_WIDTH'(1);
            end
        end
    end

    // Vertical pixel clock
    always_ff @ (posedge clk) begin
        if (rst) begin
            v_pos <= V_POS_WIDTH'(0);
        end else if (h_pos == h_pos_max) begin
            if (v_pos == v_pos_max) begin
                v_pos <= V_POS_WIDTH'(0);
            end else begin
                v_pos <= v_pos + V_POS_WIDTH'(1);
            end
        end
    end

    // Horizontal sync
    always_ff @ (posedge clk) begin
        if (rst) begin
            hsync <= 1'b0;
        end else if (h_pos == h_pos_sync_start) begin
            hsync <= 1'b1;
        end else if (h_pos == h_pos_sync_end) begin
            hsync <= 1'b0;
        end
    end

    // Vertical sync
    always_ff @ (posedge clk) begin
        if (rst) begin
            vsync <= 1'b0;
        end else if (h_pos == h_pos_sync_start) begin
            if (v_pos == v_pos_sync_start) begin
                vsync <= 1'b1;
            end
            if (v_pos == v_pos_sync_end) begin
                vsync <= 1'b0;
            end
        end
    end

    // Horizontal blank
    always_ff @ (posedge clk) begin
        if (rst) begin
            hblank <= 1'b0;
        end else if (h_pos == h_pos_blank_start) begin
            hblank <= 1'b1;
        end else if (h_pos == h_pos_blank_end) begin
            hblank <= 1'b0;
        end
    end

    // Vertical blank
    always_ff @ (posedge clk) begin
        if (rst) begin
            vblank <= 1'b0;
        end else if (h_pos == h_pos_sync_start) begin
            if (v_pos == v_pos_blank_start) begin
                vblank <= 1'b1;
            end
            if (v_pos == v_pos_blank_end) begin
                vblank <= 1'b0;
            end
        end
    end

    // Read address
    always_ff @ (posedge clk) begin
        if (rst) begin
            adr_upper <= 6'd2;
            adr_lower <= 3'd0;
        end else begin
            if (cyc && ack) begin
                if (adr_lower == 3'd4) begin
                    if (adr_upper == 6'd24) begin
                        adr_upper <= 6'd0;
                    end else begin
                        adr_upper <= adr_upper + 7'd1;
                    end
                    adr_lower <= 3'd0;
                end else begin
                    adr_lower <= adr_lower + 3'd1;
                end
            end
        end
    end

    // Wishbone cycle
    always_ff @ (posedge clk) begin
        if (rst) begin
            cyc <= 1'b0;
        end else begin
            if ((render_line_index == 6'd32 || render_line_index  < 6'd24) && render_line_subindex == 4'd15 && (h_pos == H_POS_WIDTH'(H_PIXELS - 1) || h_pos == H_POS_WIDTH'(H_PIXELS * 2 - 1))) begin
                cyc <= 1'b1;
            end else if (cyc && ack && adr_lower == 3'd4) begin
                cyc <= 1'b0;
            end
        end
    end

    // Left pixel buffer
    always_ff @ (posedge clk) begin
        if (cyc && ack && !load_right) begin
            pixel_buffer_left <= {wb_pixels, pixel_buffer_left[119:24]};
        end else if (!render_right_buffer && render_pixel_subindex == 3'd7 && h_pos[0] == 1'b1) begin
            pixel_buffer_left <= {pixel_buffer_left[23:0], pixel_buffer_left[119:24]};
        end
    end

    // Right pixel buffer
    always_ff @ (posedge clk) begin
        if (cyc && ack && load_right) begin
            pixel_buffer_right <= {wb_pixels, pixel_buffer_right[119:24]};
        end else if (render_right_buffer && render_pixel_subindex == 3'd7 && h_pos[0] == 1'b1) begin
            pixel_buffer_right <= {pixel_buffer_right[23:0], pixel_buffer_right[119]};
        end
    end
endmodule