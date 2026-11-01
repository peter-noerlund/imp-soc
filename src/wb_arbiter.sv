`default_nettype none

//! Wishbone 2:1 Arbiter
//!
//! Connects two master to a wishbone bus
//!
//! The master connected to WB_IN0 will take priority over WB_IN1
module wb_arbiter
    #(
        parameter int ADDR_WIDTH=32,            //! Address width
        parameter int DATA_WIDTH=32,            //! Data width
        parameter int SEL_WIDTH=DATA_WIDTH / 8  //! Selector width
    )
    (
        input wire clk,
        input wire rst,

        //! @virtualbus WB_IN0 @dir input Wishbone input bus
        input wire wb_in0_cyc,                          //! Wishbone signal CYC_I
        input wire wb_in0_stb,                          //! Wishbone signal STB_I
        input wire [ADDR_WIDTH - 1 : 0] wb_in0_adr,     //! Wishbone signal ADR_I
        input wire wb_in0_we,                           //! Wishbone signal WE_I
        input wire [SEL_WIDTH - 1 : 0] wb_in0_sel,      //! Wishbone signal SEL_I
        input wire [DATA_WIDTH - 1 : 0] wb_in0_dat,     //! Wishbone signal DAT_I
        input wire [2:0] wb_in0_cti,                    //! Wishbone signal CTI_I
        input wire [1:0] wb_in0_bte,                    //! Wishbone signal BTE_I
        output wire wb_in0_ack,                         //! Wishbone signal ACK_O
        output wire wb_in0_err,                         //! Wishbone signal ERR_O
        output wire wb_in0_rty,                         //! Wishbone signal RTY_O
        output wire [DATA_WIDTH - 1 : 0] wb_in0_rdt,    //! Wishbone signal DAT_O
        //! @end

        //! @virtualbus WB_IN1 @dir input Wishbone input bus
        input wire wb_in1_cyc,                          //! Wishbone signal CYC_I
        input wire wb_in1_stb,                          //! Wishbone signal STB_I
        input wire [ADDR_WIDTH - 1 : 0] wb_in1_adr,     //! Wishbone signal ADR_I
        input wire wb_in1_we,                           //! Wishbone signal WE_I
        input wire [SEL_WIDTH - 1 : 0] wb_in1_sel,      //! Wishbone signal SEL_I
        input wire [DATA_WIDTH - 1 : 0] wb_in1_dat,     //! Wishbone signal DAT_I
        input wire [2:0] wb_in1_cti,                    //! Wishbone signal CTI_I
        input wire [1:0] wb_in1_bte,                    //! Wishbone signal BTE_I
        output wire wb_in1_ack,                         //! Wishbone signal ACK_O
        output wire wb_in1_err,                         //! Wishbone signal ERR_O
        output wire wb_in1_rty,                         //! Wishbone signal RTY_O
        output wire [DATA_WIDTH - 1 : 0] wb_in1_rdt,    //! Wishbone signal DAT_O
        //! @end

        //! @virtualbus WB_OUT @dir output Wishbone output bus (lower range)
        output wire wb_out_cyc,                         //! Wishbone signal CYC_O
        output wire wb_out_stb,                         //! Wishbone signal STB_O
        output wire [ADDR_WIDTH - 1 : 0] wb_out_adr,    //! Wishbone signal ADR_O
        output wire wb_out_we,                          //! Wishbone signal WE_O
        output wire [SEL_WIDTH - 1 : 0] wb_out_sel,     //! Wishbone signal SEL_O
        output wire [DATA_WIDTH - 1 : 0] wb_out_dat,    //! Wishbone signal DAT_O
        output wire [2:0] wb_out_cti,                   //! Wishbone signal CTI_O
        output wire [1:0] wb_out_bte,                   //! Wishbone signal BTE_O
        input wire wb_out_ack,                          //! Wishbone signal ACK_I
        input wire wb_out_err,                          //! Wishbone signal ERR_I
        input wire wb_out_rty,                          //! Wishbone signal RTY_I
        input wire [DATA_WIDTH - 1 : 0] wb_out_rdt      //! Wishbone signal DAT_I
        //! @end
    );

    bit cyc;
    bit gnt;
    wire gnt0;
    wire gnt1;

    assign gnt0 = gnt;
    assign gnt1 = ~gnt;

    assign wb_in0_ack = wb_out_ack & gnt0;
    assign wb_in0_rty = wb_out_err & gnt0;
    assign wb_in0_err = wb_out_err & gnt0;
    assign wb_in0_rdt = wb_out_rdt;

    assign wb_in1_ack = wb_out_ack & gnt1;
    assign wb_in1_rty = wb_out_rty & gnt1;
    assign wb_in1_err = wb_out_err & gnt1;
    assign wb_in1_rdt = wb_out_rdt;

    assign wb_out_cyc = cyc;
    assign wb_out_stb = gnt0 ? wb_in0_stb : wb_in1_stb;
    assign wb_out_adr = gnt0 ? wb_in0_adr : wb_in1_adr;
    assign wb_out_we = gnt0 ? wb_in0_we : wb_in1_we;
    assign wb_out_sel = gnt0 ? wb_in0_sel : wb_in1_sel;
    assign wb_out_dat = gnt0 ? wb_in0_dat : wb_in1_dat;
    assign wb_out_cti = gnt0 ? wb_in0_cti : wb_in1_cti;
    assign wb_out_bte = gnt0 ? wb_in0_bte : wb_in1_bte;
    
    always_ff @ (posedge clk) begin
        if (rst) begin
            cyc <= 1'b0;
            gnt <= 1'b0;
        end else begin
            if (cyc) begin
                cyc <= (gnt0 & wb_in0_cyc) | (gnt1 & wb_in1_cyc);
            end else begin
                gnt <= wb_in0_cyc;
                cyc <= wb_in0_cyc | wb_in1_cyc;
            end
        end
    end
endmodule
