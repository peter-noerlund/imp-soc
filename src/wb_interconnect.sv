`default_nettype none

module wb_interconnect
    #(
        parameter ADDR_WIDTH=32,                    //! Address width
        parameter DATA_WIDTH=32,                    //! Data width
        parameter SEL_WIDTH=DATA_WIDTH / 8          //! Selector width
    )
    (
        //! @virtualbus WB_IN @dir input Wishbone input bus
        input wire wb_in_cyc,                           //! Wishbone signal CYC_I
        input wire wb_in_stb,                           //! Wishbone signal STB_I
        input wire [ADDR_WIDTH - 1 : 0] wb_in_adr,      //! Wishbone signal ADR_I
        input wire wb_in_we,                            //! Wishbone signal WE_I
        input wire [SEL_WIDTH - 1 : 0] wb_in_sel,       //! Wishbone signal SEL_I
        input wire [DATA_WIDTH - 1 : 0] wb_in_dat,      //! Wishbone signal DAT_I
        input wire [2:0] wb_in_cti,                     //! Wishbone signal CTI_I
        input wire [1:0] wb_in_bte,                     //! Wishbone signal BTE_I
        output wire wb_in_ack,                          //! Wishbone signal ACK_O
        output wire wb_in_err,                          //! Wishbone signal ERR_O
        output wire wb_in_rty,                          //! Wishbone signal RTY_O
        output wire [DATA_WIDTH - 1 : 0] wb_in_rdt,     //! Wishbone signal DAT_O
        //! @end

        //! @virtualbus WB_OUT0 @dir output Wishbone output bus (lower range)
        output wire wb_out0_cyc,                        //! Wishbone signal CYC_O
        output wire wb_out0_stb,                        //! Wishbone signal STB_O
        output wire [ADDR_WIDTH - 2 : 0] wb_out0_adr,   //! Wishbone signal ADR_O
        output wire wb_out0_we,                         //! Wishbone signal WE_O
        output wire [SEL_WIDTH - 1 : 0] wb_out0_sel,    //! Wishbone signal SEL_O
        output wire [DATA_WIDTH - 1 : 0] wb_out0_dat,   //! Wishbone signal DAT_O
        output wire [2:0] wb_out0_cti,                  //! Wishbone signal CTI_O
        output wire [1:0] wb_out0_bte,                  //! Wishbone signal BTE_O
        input wire wb_out0_ack,                         //! Wishbone signal ACK_I
        input wire wb_out0_err,                         //! Wishbone signal ERR_I
        input wire wb_out0_rty,                         //! Wishbone signal RTY_I
        input wire [DATA_WIDTH - 1 : 0] wb_out0_rdt,    //! Wishbone signal DAT_I
        //! @end

        //! @virtualbus WB_OUT1 @dir output Wishbone output bus (upper range)
        output wire wb_out1_cyc,                        //! Wishbone signal CYC_O
        output wire wb_out1_stb,                        //! Wishbone signal STB_O
        output wire [ADDR_WIDTH - 2 : 0] wb_out1_adr,   //! Wishbone signal ADR_O
        output wire wb_out1_we,                         //! Wishbone signal WE_O
        output wire [SEL_WIDTH - 1 : 0] wb_out1_sel,    //! Wishbone signal SEL_O
        output wire [DATA_WIDTH - 1 : 0] wb_out1_dat,   //! Wishbone signal DAT_O
        output wire [2:0] wb_out1_cti,                  //! Wishbone signal CTI_O
        output wire [1:0] wb_out1_bte,                  //! Wishbone signal BTE_O
        input wire wb_out1_ack,                         //! Wishbone signal ACK_I
        input wire wb_out1_err,                         //! Wishbone signal ERR_I
        input wire wb_out1_rty,                         //! Wishbone signal RTY_I
        input wire [DATA_WIDTH - 1 : 0] wb_out1_rdt     //! Wishbone signal DAT_I
        //! @end        
    );

    wire acmp0;
    wire acmp1;

    assign acmp0 = ~wb_in_adr[ADDR_WIDTH - 1];
    assign acmp1 = wb_in_adr[ADDR_WIDTH - 1];

    assign wb_out0_cyc = wb_in_cyc;
    assign wb_out1_cyc = wb_in_cyc;

    assign wb_out0_stb = wb_in_cyc & wb_in_stb & acmp0;
    assign wb_out1_stb = wb_in_cyc & wb_in_stb & acmp1;

    assign wb_out0_adr = wb_in_adr[ADDR_WIDTH - 2 : 0];
    assign wb_out1_adr = wb_in_adr[ADDR_WIDTH - 2 : 0];

    assign wb_out0_we = wb_in_we;
    assign wb_out1_we = wb_in_we;

    assign wb_out0_sel = wb_in_sel;
    assign wb_out1_sel = wb_in_sel;

    assign wb_out0_dat = wb_in_dat;
    assign wb_out1_dat = wb_in_dat;

    assign wb_out0_cti = wb_in_cti;
    assign wb_out1_cti = wb_in_cti;

    assign wb_out0_bte = wb_in_bte;
    assign wb_out1_bte = wb_in_bte;

    assign wb_in_ack = wb_out0_ack | wb_out1_ack;
    assign wb_in_err = wb_out0_err | wb_out1_err;
    assign wb_in_rty = wb_out0_rty | wb_out1_rty;

    assign wb_in_rdt = acmp0 ? wb_out0_rdt : wb_out1_rdt;
endmodule
