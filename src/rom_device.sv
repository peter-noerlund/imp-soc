`default_nettype none

module rom_device
    #(
        parameter int WORD_COUNT=8,
        parameter [32 * WORD_COUNT - 1 :0] ROM,
        parameter int ADDR_WIDTH = $clog2(WORD_COUNT * 4)
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
        output wire [31:0] wb_rdt
    );

    assign wb_ack = ~rst & wb_cyc & wb_stb;
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;

    wire [31:0] rom [WORD_COUNT - 1 : 0];

    genvar i;

    generate
        for (i = 0; i != WORD_COUNT; i++) begin
            assign rom[i] = ROM[i * 32 + 31 -: 32];
        end
    endgenerate

    assign wb_rdt = rom[wb_adr[ADDR_WIDTH - 1 : 2]];

    wire _unused = &{clk, wb_adr[1:0], wb_we, wb_sel, wb_dat, wb_cti, wb_bte};
endmodule

