`default_nettype none

module video_device
    #(
        parameter int ADDR_WIDTH=32,
        parameter int FB_ADDR_WIDTH=24
    )
    (
        input wire clk,
        input wire rst,

        input wire wb_cyc,
        input wire wb_stb,
        input wire [ADDR_WIDTH - 1 : 0] wb_adr,
        input wire wb_we,
        input wire [3:0] wb_sel,
        input wire [2:0] wb_cti,
        input wire [1:0] wb_bte,
        input wire [31:0] wb_dat,
        output wire wb_ack,
        output wire wb_rty,
        output wire wb_err,
        output wire [31:0] wb_rdt,

        output wire fb_enabled,
        output wire [FB_ADDR_WIDTH - 1 : 0] fb_addr
    );

    localparam int INTERNAL_ADDR_WIDTH = FB_ADDR_WIDTH - 6;

    bit ack;
    bit [INTERNAL_ADDR_WIDTH - 1 : 0] addr;   // 24 bit
    bit enabled;

    assign wb_ack = ack && !rst && wb_cyc && wb_stb;
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;
    assign wb_rdt = 32'h00000000;
    assign fb_addr = {addr, 6'h00};
    assign fb_enabled = enabled;

    always_ff @ (posedge clk) begin
        if (rst || !wb_cyc || !wb_stb) begin
            ack <= 1'b0;
            enabled <= 1'b0;
            addr <= INTERNAL_ADDR_WIDTH'(0);
        end else begin
            if (!ack) begin
                if (wb_we) begin
                    enabled <= wb_dat[31];
                    addr <= wb_dat[FB_ADDR_WIDTH - 1 : 6];
                end
                ack <= 1'b1;
            end

            if (ack) begin
                ack <= 1'b0;
            end
        end
    end
endmodule
