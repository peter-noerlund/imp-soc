`default_nettype none

/*
Module generating VESA VGA timing. See VESA DMT spec for details:

https://glenwing.github.io/docs/VESA-DMT-1.13.pdf
*/
module vga_timing
    #(
        parameter int H_PIXELS = 1024,              //! Horizontal visible pixels
        parameter int V_PIXELS = 768,               //! Vertical visible lines

        parameter int H_RIGHT_BORDER = 0,           //! Horizontal right border in pixels
        parameter int H_FRONT_PORCH = 24,           //! Horizontal front porch in pixels
        parameter int H_SYNC_TIME = 136,            //! Horizontal sync time in pixels
        parameter int H_BACK_PORCH = 160,           //! Horizontal back porch in pixels
        parameter int H_LEFT_BORDER = 0,            //! Horizontal right border in pixels

        parameter int V_BOTTOM_BORDER = 0,          //! Vertical bottom border in lines
        parameter int V_FRONT_PORCH = 3,            //! Vertical front porch in lines
        parameter int V_SYNC_TIME = 6,              //! Vertical sync time in lines
        parameter int V_BACK_PORCH = 29,            //! Vertical back porch in lines
        parameter int V_TOP_BORDER = 0,             //! Vertical top border in lines

        parameter [0:0] H_SYNC_POLARITY = 0,        //! Horizontal sync polarity (0=negative, 1=positive)
        parameter [0:0] V_SYNC_POLARITY = 0,        //! Vertical sync polarity (0=negative, 1=positive)
        
        parameter int H_POS_WIDTH = $clog2(H_PIXELS + H_RIGHT_BORDER + H_FRONT_PORCH + H_SYNC_TIME + H_BACK_PORCH + H_LEFT_BORDER),
        parameter int V_POS_WIDTH = $clog2(V_PIXELS + V_BOTTOM_BORDER + V_FRONT_PORCH + V_SYNC_TIME + V_BACK_PORCH + V_TOP_BORDER)
    )
    (
        input wire clk,                             //! Input clock. Must match pixel clock
        input wire rst,                             //! Reset

        output wire [H_POS_WIDTH - 1 : 0] vga_hpos, //! Horizontal pixel position, with 0 being the 1st visible pixel
        output wire [V_POS_WIDTH - 1 : 0] vga_vpos, //! Line position, with 0 being the 1st visible line
        output wire vga_vsync,                      //! Vertical sync
        output wire vga_hsync,                      //! Horizontal sync
        output wire vga_blank                       //! Blanking
    );

    localparam int H_POS_BLANK_START    = H_PIXELS - 1;
    localparam int H_POS_SYNC_START     = H_PIXELS + H_RIGHT_BORDER + H_FRONT_PORCH - 1;
    localparam int H_POS_SYNC_END       = H_PIXELS + H_RIGHT_BORDER + H_FRONT_PORCH + H_SYNC_TIME - 1;
    localparam int H_POS_BLANK_END      = H_PIXELS + H_RIGHT_BORDER + H_FRONT_PORCH + H_SYNC_TIME + H_BACK_PORCH + H_LEFT_BORDER - 1;
    localparam int H_POS_MAX            = H_PIXELS + H_RIGHT_BORDER + H_FRONT_PORCH + H_SYNC_TIME + H_BACK_PORCH + H_LEFT_BORDER - 1;

    localparam int V_POS_BLANK_START    = V_PIXELS - 1;
    localparam int V_POS_SYNC_START     = V_PIXELS + V_BOTTOM_BORDER + V_FRONT_PORCH - 1;
    localparam int V_POS_SYNC_END       = V_PIXELS + V_BOTTOM_BORDER + V_FRONT_PORCH + V_SYNC_TIME - 1;
    localparam int V_POS_BLANK_END      = V_PIXELS + V_BOTTOM_BORDER + V_FRONT_PORCH + V_SYNC_TIME + V_BACK_PORCH + V_TOP_BORDER - 1;
    localparam int V_POS_MAX            = V_PIXELS + V_BOTTOM_BORDER + V_FRONT_PORCH + V_SYNC_TIME + V_BACK_PORCH + V_TOP_BORDER - 1;

    bit [H_POS_WIDTH - 1 : 0] h_pos;
    bit [V_POS_WIDTH - 1 : 0] v_pos;
    bit h_blank;
    bit v_blank;
    bit h_sync;
    bit v_sync;

    assign vga_hpos = h_pos;
    assign vga_vpos = v_pos;
    assign vga_hsync = h_sync;
    assign vga_vsync = v_sync;
    assign vga_blank = v_blank | h_blank;

    // Horizontal pixel clock
    always_ff @ (posedge clk) begin
        if (rst) begin
            h_pos <= H_POS_WIDTH'(0);
        end else begin
            if (h_pos == H_POS_WIDTH'(H_POS_MAX)) begin
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
        end else if (h_pos == H_POS_WIDTH'(H_POS_SYNC_START)) begin // TODO - Do we want the line to shift here or at the vsync?
            if (v_pos == V_POS_WIDTH'(V_POS_MAX)) begin
                v_pos <= V_POS_WIDTH'(0);
            end else begin
                v_pos <= v_pos + V_POS_WIDTH'(1);
            end
        end
    end

    // Horizontal sync
    always_ff @ (posedge clk) begin
        if (rst) begin
            h_sync <= !H_SYNC_POLARITY;
        end else begin
            if (h_pos == H_POS_WIDTH'(H_POS_SYNC_START)) begin
                h_sync <= H_SYNC_POLARITY;
            end
            if (h_pos == H_POS_WIDTH'(H_POS_SYNC_END)) begin
                h_sync <= !H_SYNC_POLARITY;
            end
        end
    end
    
    // Vertical sync
    always_ff @ (posedge clk) begin
        if (rst) begin
            v_sync <= !V_SYNC_POLARITY;
        end else if (h_pos == H_POS_WIDTH'(H_POS_SYNC_START)) begin
            if (v_pos == V_POS_WIDTH'(V_POS_SYNC_START)) begin
                v_sync <= V_SYNC_POLARITY;
            end
            if (v_pos == V_POS_WIDTH'(V_POS_SYNC_END)) begin
                v_sync <= !V_SYNC_POLARITY;
            end
        end
    end

    // Horizontal blank
    always_ff @ (posedge clk) begin
        if (rst) begin
            h_blank <= 1'b0;
        end else begin
            if (h_pos == H_POS_WIDTH'(H_POS_BLANK_START)) begin
                h_blank <= 1'b1;
            end
            if (h_pos == H_POS_WIDTH'(H_POS_BLANK_END)) begin
                h_blank <= 1'b0;
            end
        end
    end

    // Vertical blank
    always_ff @ (posedge clk) begin
        if (rst) begin
            v_blank <= 1'b0;
        end else if (h_pos == H_POS_WIDTH'(H_POS_SYNC_START)) begin
            if (v_pos == V_POS_WIDTH'(V_POS_BLANK_START)) begin
                v_blank <= 1'b1;
            end
            if (v_pos == V_POS_WIDTH'(V_POS_BLANK_END)) begin
                v_blank <= 1'b0;
            end
        end
    end
endmodule
