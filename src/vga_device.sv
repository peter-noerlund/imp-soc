`default_nettype none


module vga_device
    #(
        parameter int ADDR_WIDTH=32
    )
    (
        input wire clk,
        input wire rst,

        input wire wb_cyc,
        input wire wb_stb,
        /* verilator lint_off UNUSEDSIGNAL */
        input wire [ADDR_WIDTH - 1 :0] wb_adr,
        input wire wb_we,
        input wire [3:0] wb_sel,
        input wire [2:0] wb_cti,
        input wire [1:0] wb_bte,
        input wire [31:0] wb_dat,
        /* verilator lint_on UNUSEDSIGNAL */
        output wire wb_ack,
        output wire wb_rty,
        output wire wb_err,
        output wire [31:0] wb_rdt,

        output wire vgaconfig_enabled,
        output wire [ADDR_WIDTH - 1 : 0] vgaconfig_addr
    );

    bit enabled;
    bit [ADDR_WIDTH - 15 : 0] addr;
    bit ack;
    
    assign wb_ack = wb_cyc & wb_stb & ack;
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;
    assign wb_rdt = wb_adr[2] == 1'b0 ? {31'h00000000, vgaconfig_enabled} : 32'(vgaconfig_addr);

    assign vgaconfig_enabled = enabled;
    assign vgaconfig_addr = {addr, 14'h0000};

    always_ff @ (posedge clk) begin
        ack <= !rst & wb_cyc & wb_stb;
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            enabled <= 1'b0;
        end else if (wb_cyc && wb_stb && wb_we && !ack && wb_adr[2] == 1'b0 && wb_sel[0] == 1'b1) begin
            enabled <= wb_dat[0];
        end
    end

    always_ff @ (posedge clk) begin
        if (!rst && wb_cyc && wb_stb && wb_we && !ack && wb_adr[2] == 1'b1 && wb_sel == 4'b1111) begin
            addr <= wb_dat[ADDR_WIDTH - 1 : 14];
        end
    end
endmodule
