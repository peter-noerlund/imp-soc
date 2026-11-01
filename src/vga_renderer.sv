`default_nettype none

module vga_renderer
    #(
        parameter int ADDR_WIDTH=32
    )
    (
        input wire clk,
        input wire rst,

        input wire vgaconfig_enabled,
        input wire [ADDR_WIDTH - 1 : 0] vgaconfig_addr,

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

    // One line is 60 bytes which takes 15 32-bit transfers.
    // With traditional transfers, competing with the CPU, this may take as much as 1,680 cycles.
    // With bursting, worst case timing is 336 cycles.
    // Right border, front porch, sync time, back porch and left border combined is (32 + 24 + 136 + 160 + 32) 384 cycles,
    // so we can initiate transfer when we reach the 160th pixel in the 7th line

    localparam [2:0] CTI_CLASSIC = 3'b000;
    localparam [2:0] CTI_INCREMENT = 3'b010;
    localparam [2:0] CTI_END_OF_BURST = 3'b111;

    localparam [2:0] BTE_LINEAR = 2'b00;

    wire vga_blank;
    wire [10:0] vga_hpos;
    wire [9:0] vga_vpos;

    wire [2:0] line_mask;
    wire last_subline;

    wire [5:0] color1;
    wire [5:0] color2;
    bit [5:0] pixel0_color;
    bit [5:0] pixel1_color;
    wire [5:0] pixel_color;
    wire [1:0] pixel_red;
    wire [1:0] pixel_green;
    wire [1:0] pixel_blue;
    wire [11:0] pixel_groups;
    wire [2:0] pixel_group;
    wire [23:0] current_chunk;

    bit cyc;
    wire ack;

    bit write_latch0;
    bit write_latch1;
    bit [31:0] write_buffer;
    bit [479:0] memory;
    bit [3:0] write_adr;
    bit [3:0] adr_lo;
    bit [6:0] adr_hi;

    genvar i;
    integer j;

    assign wb_cyc = cyc;
    assign wb_stb = cyc;
    assign wb_adr = {vgaconfig_addr[ADDR_WIDTH - 1 : 12], adr_hi, adr_lo, 2'b00};
    assign wb_we = 1'b0;
    assign wb_sel = 4'b1111;
    assign wb_cti = adr_lo == 4'd14 ? CTI_END_OF_BURST : CTI_INCREMENT;
    assign wb_bte = BTE_LINEAR;
    assign wb_dat = 32'h00000000;

    assign ack = wb_ack | wb_rty | wb_err;

    assign color1 = current_chunk[23:18];
    assign color2 = current_chunk[17:12];
    assign pixel_groups = current_chunk[11:0];
    assign pixel_group = pixel_groups[vga_hpos[3:2] * 3 + 2 -: 3];
    assign pixel_color = vga_hpos[2] == 1'b1 ? pixel1_color : pixel0_color;
    assign pixel_red = pixel_color[5:4];
    assign pixel_green = pixel_color[3:2];
    assign pixel_blue = pixel_color[1:0];

    assign vga_red = vga_blank ? 2'b00 : pixel_red;
    assign vga_green = vga_blank ? 2'b00 : pixel_green;
    assign vga_blue = vga_blank ? 2'b00 : pixel_blue;

    assign current_chunk = memory[vga_hpos[7:3] * 24 + 23 -: 24];

    always_comb begin
        case (pixel_group)
            3'd0: pixel0_color = 6'b000000; // 0 0
            3'd1: pixel0_color = color1;    // 0 1
            3'd2: pixel0_color = color2;    // 0 2
            3'd3: pixel0_color = 6'b000000; // 1 0
            3'd4: pixel0_color = color1;    // 1 1
            3'd5: pixel0_color = color2;    // 1 2
            3'd6: pixel0_color = 6'b000000; // 2 0
            3'd7: pixel0_color = color2;    // 2 2
        endcase
    end

    always_comb begin
        case (pixel_group)
            3'd0: pixel1_color = 6'b000000; // 0 0
            3'd1: pixel1_color = 6'b000000; // 0 1
            3'd2: pixel1_color = 6'b000000; // 0 2
            3'd3: pixel1_color = color1;    // 1 0
            3'd4: pixel1_color = color1;    // 1 1
            3'd5: pixel1_color = color1;    // 1 2
            3'd6: pixel1_color = color2;    // 2 0
            3'd7: pixel1_color = color2;    // 2 2
        endcase
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            cyc <= 1'b0;
        end else if (vga_hpos == 11'd639 && vga_vpos[1:0] == 2'b11 && adr_hi != 7'd100) begin
            cyc <= 1'b1;
        end else if (cyc && ack && adr_lo == 4'd14) begin
            cyc <= 1'b0;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            adr_hi <= 7'd1;
        end else if (cyc && ack && adr_lo == 4'd14) begin
            adr_hi <= adr_hi + 7'd1; // FIXME
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            adr_lo <= 4'd0;
        end else if (cyc & ack) begin
            if (adr_lo <= 4'd14) begin
                adr_lo <= 4'd0;
            end else begin
                adr_lo <= adr_lo + 4'd1;
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (!rst && cyc && ack) begin
            write_buffer <= wb_rdt;
        end
    end

    always_ff @ (posedge clk) begin
        write_latch0 <= !rst && cyc && ack;
    end

    always_ff @ (posedge clk) begin
        write_latch1 <= !rst && write_latch0;
    end

    always_ff @ (posedge clk) begin
        if (!rst && cyc && ack) begin
            write_adr <= adr_lo;
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

`ifdef FPGA
    // Use flip-flops on FPGA

    for (i = 0; i != 15; i++) begin
        always_ff @ (posedge clk) begin
            if (write_latch1 && write_adr == 4'(i)) begin
                memory[i * 32 + 31 -: 32] <= write_buffer;
            end
        end
    end
`else
    // Use latch on ASIC

    for (i = 0; i != 15; i++) begin
        always_latch begin
            if (write_latch1 && write_adr == 4'(i)) begin
                memory[i * 32 + 31 -: 32] = write_buffer;
            end
        end
    end
`endif
endmodule