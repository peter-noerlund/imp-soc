`default_nettype none

module vga_renderer
    #(
        parameter int ADDR_WIDTH=32
    )
    (
        input wire clk,
        input wire rst,

        input wire vgaconfig_enabled,
        input wire [3:0] vgaconfig_scale,
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

    bit write_latch;
    bit [31:0] write_buffer;
    bit [479:0] memory;
    bit [3:0] write_addr;

    genvar i;

    assign wb_dat = 32'h00000000;
    assign wb_sel = 4'b1111;

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
            if (write_latch && write_addr == 4'(i)) begin
                memory[i * 32 + 31 -: 32] <= write_buffer;
            end
        end
    end
`else
    // Use latch on ASIC

    for (i = 0; i != 15; i++) begin
        always_latch begin
            if (write_latch && write_addr == 4'(i)) begin
                memory[i * 32 + 31 -: 32] = write_buffer;
            end
        end
    end
`endif
endmodule