`default_nettype none


module vga_device
    #(
        parameter int ADDR_WIDTH=32,
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

    bit vgaconfig_enabled_mem;
    bit [ADDR_WIDTH - ALIGN_WIDTH - 1 : 0] vgaconfig_addr_mem;
    bit ack;
    bit wreq;
    
    assign wb_ack = wb_cyc & wb_stb & ack;
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;
    assign wb_rdt = DATA_WIDTH'(0);

    assign vgaconfig_enabled = vgaconfig_enabled_mem;
    assign vgaconfig_addr = {vgaconfig_addr_mem, ALIGN_WIDTH'(0)};

    always_ff @ (posedge clk) begin
        wreq <= ~rst & wb_cyc & wb_stb & ~ack & wb_we & ~wreq;
        ack <= ~rst & wb_cyc & wb_stb & ~ack & (wreq | ~wb_we);
    end

`ifdef FPGA
    always_ff @ (posedge clk) begin
        if (wreq) begin
            vgaconfig_enabled_mem <= wb_dat[DATA_WIDTH - 1];
            vgaconfig_addr_mem <= wb_dat[ADDR_WIDTH - 1 : ALIGN_WIDTH];
        end
    end
`else
    always_latch begin
        if (wreq) begin
            vgaconfig_enabled_mem = wb_dat[DATA_WIDTH - 1];
            vgaconfig_addr_mem = wb_dat[ADDR_WIDTH - 1 : ALIGN_WIDTH];
        end
    end
`endif

    wire _unused = &{wb_adr, wb_sel, wb_cti, wb_bte};
endmodule

