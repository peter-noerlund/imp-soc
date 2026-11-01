`default_nettype none

module led_device
    #(
        parameter int ADDR_WIDTH=32,
        parameter int LED_WIDTH=3
    )
    (
        input wire clk,
        input wire rst,

        input wire wb_cyc,
        input wire wb_stb,
        input wire [ADDR_WIDTH - 1 : 0] wb_adr,
        input wire wb_we,
        input wire [3:0] wb_sel,
        input wire [31:0] wb_dat,
        input wire [2:0] wb_cti,
        input wire [1:0] wb_bte,
        output wire wb_ack,
        output wire wb_rty,
        output wire wb_err,
        output wire [31:0] wb_rdt,

        output wire [LED_WIDTH - 1 : 0] leds
    );

    bit [LED_WIDTH - 1 : 0] leds_mem;
    bit ack;

    assign leds = leds_mem;

    assign wb_ack = wb_cyc & wb_stb & ack;
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;
    assign wb_rdt = 32'(leds);

    always_ff @ (posedge clk) begin
        if (rst) begin
            ack <= 1'b0;
        end else if (wb_cyc && wb_stb && !ack) begin
            ack <= 1'b1;
        end else begin
            ack <= 1'b0;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            leds_mem <= LED_WIDTH'(0);
        end else if (wb_cyc && wb_stb && wb_we) begin
            leds_mem <= wb_dat[LED_WIDTH - 1 : 0];
        end
    end

    wire _unused = &{wb_adr, wb_we, wb_sel, wb_dat, wb_dat, wb_cti, wb_bte};
endmodule
