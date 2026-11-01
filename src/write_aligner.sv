`default_nettype none

/**
  * Write Aligner
  *
  * Take a 32-bit aligned conventional wishbone bus and realigns it so that the only valid values of SEL for writes are 4'b0001 for byte write, 4'b0011 for two-byte write and 4'b1111 for four-byte write.
  *
  * Read operations are unmodified
  */
module write_aligner
    #(
        parameter ADDR_WIDTH=32 //! Width of address
    )
    (
        //! @virtualbus WB_IN @dir input Wishbone in
        /* verilator lint_off UNUSEDSIGNAL */
        input wire [ADDR_WIDTH-1:0] wb_in_adr,      //! Wishbone signal ADR_I
        /* verilator lint_on UNUSEDSIGNAL */
        input wire wb_in_we,                        //! Wishbone signal WE_I
        input wire [3:0] wb_in_sel,                 //! Wishbone signal SEL_I
        input wire [31:0] wb_in_dat,                //! Wishbone signal DAT_I
        input wire [2:0] wb_in_cti,                 //! Wishbone signal CTI_O
        input wire [1:0] wb_in_bte,                 //! Wishbone signal BTE_O
        //! @end

        //! @virtualbus WB_OUT @dir output Wishbone out
        output wire [ADDR_WIDTH-1:0] wb_out_adr,    //! Wishbone signal ADR_O
        output wire [3:0] wb_out_sel,               //! Wishbone signal SEL_O
        output wire [31:0] wb_out_dat,              //! Wishbone signal DAT_O
        output wire [2:0] wb_out_cti,               //! Wishbone signal CTI_O
        output wire [1:0] wb_out_bte                //! Wishbone signal BTE_O
        //! @end
    );

    logic [3:0] sel;
    logic [1:0] adr_lsb;
    logic [15:0] dat_lsb;

    assign wb_out_adr = {wb_in_adr[ADDR_WIDTH-1:2], adr_lsb};
    assign wb_out_dat = {wb_in_dat[31:16], dat_lsb};
    assign wb_out_sel = sel;
    assign wb_out_cti = wb_in_we ? 3'b000 : wb_in_cti;
    assign wb_out_bte = wb_in_we ? 2'b00 : wb_in_bte;

    always_comb begin
        case ({wb_in_we, wb_in_sel})
            5'b10010: begin
                sel = 4'b0001;
                adr_lsb = 2'd1;
                dat_lsb = {8'h00, wb_in_dat[15:8]};
            end

            5'b10100: begin
                sel = 4'b0001;
                adr_lsb = 2'd2;
                dat_lsb = {8'h00, wb_in_dat[23:16]};
            end

            5'b11000: begin
                sel = 4'b0001;
                adr_lsb = 2'd3;
                dat_lsb = {8'h00, wb_in_dat[31:24]};
            end

            5'b11100: begin
                sel = 4'b0011;
                adr_lsb = 2'd2;
                dat_lsb = wb_in_dat[31:16];
            end

            default: begin
                sel = wb_in_sel;
                adr_lsb = 2'd0;
                dat_lsb = wb_in_dat[15:0];
            end
        endcase
    end
endmodule
