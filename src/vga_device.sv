`default_nettype none


/**
VGA Wishbone device

It exposes two registers:

VGA_CTRL at offset 0
VGA_ADDR at offset 4

VGA_CTRL controls how the VGA device runs:

Bit 0:      Enable flag
Bit 8-10:   Vertical scale:
                0=480 pixels
                1=240 pixels
                2=160 pixels
                3=80 pixels

VGA_ADDR controls where the frame buffer is stored. The frame buffer is 64 bytes times the vertical height.
The address must align to 64 bytes (The 14 least significant bits are always zero)

*/
module vga_device
    #(
        parameter int ADDR_WIDTH=32
    )
    (
        input wire clk,
        input wire rst,

        input wire wb_cyc,
        input wire wb_stb,
        input wire [ADDR_WIDTH - 1 :0] wb_adr,
        input wire wb_we,
        input wire [3:0] wb_sel,
        /* verilator lint_off UNUSEDSIGNAL */
        input wire [2:0] wb_cti,
        input wire [1:0] wb_bte,
        /* verilator lint_on UNUSEDSIGNAL */
        input wire [31:0] wb_dat,
        output wire wb_ack,
        output wire wb_rty,
        output wire wb_err,
        output wire [31:0] wb_rdt,

        output wire vgaconfig_enabled,
        output wire [3:0] vgaconfig_scale,
        output wire [ADDR_WIDTH - 1 : 0] vgaconfig_addr
    );

    bit enabled;
    bit [ADDR_WIDTH - 15 : 0] addr;
    bit [3:0] scale;
    bit ack;
    bit latch;
    
    assign wb_ack = wb_cyc & wb_stb & ack;
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;
    assign wb_rdt = wb_adr[2] == 1'b0 ? {20'h00000, vgaconfig_scale, 7'h00, vgaconfig_enabled} : 32'(vgaconfig_addr);

    assign vgaconfig_enabled = enabled;
    assign vgaconfig_scale = scale;
    assign vgaconfig_addr = {addr, 14'h0000};

    always_ff @ (posedge clk) begin
        ack <= !rst & wb_cyc & wb_stb & (!wb_we | latch);
    end

    always_ff @ (posedge clk) begin
        latch <= !rst & wb_cyc & wb_stb & wb_we & !latch & !ack;
    end

`ifdef FPGA
    // Use flip-flops on FPGAs

    always_ff @ (posedge clk) begin
        if (latch && wb_adr[2] == 1'b0 && wb_sel[0] == 1'b1) begin
            enabled <= wb_dat[0];
        end
        if (rst) begin
            enabled <= 1'b0;
        end
    end

    always_ff @ (posedge clk) begin
        if (latch && wb_adr[2] == 1'b0 && wb_sel[1] == 1'b1) begin
            scale <= wb_dat[11:8];
        end
    end

    always_ff @ (posedge clk) begin
        if (latch && wb_adr[2] == 1'b1 && wb_sel == 4'b1111) begin
            addr <= wb_dat[ADDR_WIDTH - 1 : 14];
        end
    end
`else // FPGA
    // Use latches on ASIC and in simulation

    always_latch begin
        if (latch && wb_adr[2] == 1'b0 && wb_sel[0] == 1'b1) begin
            enabled = wb_dat[0];
        end
        if (rst) begin
            enabled = 1'b0;
        end
    end

    always_latch begin
        if (latch && wb_adr[2] == 1'b0 && wb_sel[1] == 1'b1) begin
            scale = wb_dat[11:8];
        end
    end

    always_latch begin
        if (latch && wb_adr[2] == 1'b1 && wb_sel == 4'b1111) begin
            addr = wb_dat[ADDR_WIDTH - 1 : 14];
        end
    end
`endif // FPGA
endmodule