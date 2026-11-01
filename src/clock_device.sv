`default_nettype none

module clock_device
    #(
        parameter int ADDR_WIDTH=32,
        parameter int DATA_WIDTH=32,
        parameter int CLOCK_WIDTH=DATA_WIDTH
    )
    (
        input wire clk,
        input wire rst,

        //! @virtualbus WB @dir input Wishbone bus
        input wire wb_cyc,                              //! Wishbone CYC_I
        input wire wb_stb,                              //! Wishbone STB_I
        input wire [ADDR_WIDTH - 1 : 0] wb_adr,           //! Wishbone ADR_I
        input wire wb_we,                               //! Wishbone WE_I
        input wire [(DATA_WIDTH / 8) - 1 : 0] wb_sel,   //! Wishbone SEL_I
        input wire [DATA_WIDTH - 1 : 0] wb_dat,         //! Wishbone DAT_I
        input wire [2:0] wb_cti,                        //! Wishbone CTI_I
        input wire [1:0] wb_bte,                        //! Wishbone BTE_I
        output wire wb_ack,                             //! Wishbone ACK_O
        output wire wb_rty,                             //! Wishbone RTY_O
        output wire wb_err,                             //! Wishbone ERR_O
        output wire [DATA_WIDTH - 1 : 0] wb_rdt         //! Wishbone DAT_O
        //! @end
    );

    bit [CLOCK_WIDTH - 1 : 0] clock;

    assign wb_rdt = clock;
    assign wb_ack = !rst && wb_cyc && wb_stb;
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;

    always_ff @ (posedge clk) begin
        if (rst) begin
            clock <= CLOCK_WIDTH'(0);
        end else begin
            clock <= clock + CLOCK_WIDTH'(1);
        end
    end
endmodule
