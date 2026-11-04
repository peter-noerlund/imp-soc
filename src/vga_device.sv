`default_nettype none


module vga_device
    #(
        parameter int ADDR_WIDTH=31,
        parameter int DATA_WIDTH=32,
        parameter int ALIGN_WIDTH=14
    )
    (
        input wire clk,
        input wire rst,

        input wire wb_cyc,
        input wire wb_stb,
        input wire [ADDR_WIDTH - 1 :0] wb_adr,
        input wire wb_we,
        input wire [(DATA_WIDTH / 8) - 1 : 0] wb_sel,
        input wire [2:0] wb_cti,
        input wire [1:0] wb_bte,
        input wire [DATA_WIDTH - 1 : 0] wb_dat,
        output wire wb_ack,
        output wire wb_rty,
        output wire wb_err,
        output wire [DATA_WIDTH - 1 : 0] wb_rdt,

        output wire vgaconfig_enabled,
        output wire [ADDR_WIDTH - 1 : 0] vgaconfig_addr
    );

    localparam int ADDR_MEM_WIDTH = ADDR_WIDTH - ALIGN_WIDTH;

    bit vgaconfig_enabled_mem;
    bit [ADDR_MEM_WIDTH - 1 : 0] vgaconfig_addr_mem;
    bit ack;
    
    assign wb_ack = wb_cyc & wb_stb & ack;
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;
    assign wb_rdt = DATA_WIDTH'(0);

    assign vgaconfig_enabled = vgaconfig_enabled_mem;
    assign vgaconfig_addr = {vgaconfig_addr_mem, ALIGN_WIDTH'(0)};

    always_ff @ (posedge clk) begin
        ack <= ~rst & wb_cyc & wb_stb & ~ack;
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            vgaconfig_enabled_mem <= 1'b0;
        end else if (wb_cyc & wb_stb & wb_we & ~ack) begin
            vgaconfig_enabled_mem <= wb_dat[DATA_WIDTH - 1];
            vgaconfig_addr_mem <= wb_dat[ADDR_WIDTH - 1 : ALIGN_WIDTH];
        end
    end

    wire _unused = &{wb_adr, wb_sel, wb_cti, wb_bte};
endmodule

