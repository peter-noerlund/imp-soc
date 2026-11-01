`default_nettype none

module cpu
    (
        input wire clk,
        input wire rst,

        //! @virtualbus WB @dir output Memory bus
        output wire wb_cyc,         //! Wishbone signal CYC_O
        output wire wb_stb,         //! Wishbone signal STB_O
        output wire [31:0] wb_adr,  //! Wishbone signal ADR_O
        output wire wb_we,          //! Wishbone signal WE_O
        output wire [3:0] wb_sel,   //! Wishbone signal SEL_O
        output wire [31:0] wb_dat,  //! Wishbone signal DAT_O
        output wire [2:0] wb_cti,   //! Wishbone signal CTI_O
        output wire [1:0] wb_bte,   //! Wishbone signal BTE_O
        input wire wb_ack,          //! Wishbone signal ACK_I
        input wire wb_err,          //! Wishbone signal ERR_I
        input wire wb_rty,          //! Wishbone signal RTY_I
        input wire [31:0] wb_rdt    //! Wishbone signal DAT_I
        //! @end
    );

    // Register File interface
    wire rf_rreq;
    wire rf_wreq;
    wire rf_ready;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [4:0] rf_wreg0;
    wire [4:0] rf_rreg0;
    wire [4:0] rf_rreg1;
    /* verilator lint_on UNUSEDSIGNAL */
    wire rf_wen0;
    wire rf_wdata0;
    wire rf_rdata0;
    wire rf_rdata1;

    // Instruction bus
    wire ibus_cyc;
    wire [31:0] ibus_adr;
    wire [31:0] ibus_rdt;
    wire ibus_ack;
    
    // Data bus
    wire dbus_cyc;
    wire [31:0] dbus_adr;
    wire dbus_we;
    wire [3:0] dbus_sel;
    wire [31:0] dbus_dat;
    wire dbus_ack; 
    wire [31:0] dbus_rdt;

    // RAM-based register file bus
    /*
    wire [8:0] sram_waddr;
    wire [1:0] sram_wdata;
    wire sram_wen;
    wire [8:0] sram_raddr;
    wire [1:0] sram_rdata;
    wire sram_ren;
    */

    assign wb_cti = 3'b000;
    assign wb_bte = 2'b00;
    assign wb_cyc = wb_stb;
    
    /* verilator lint_off PINMISSING */
    serv_top #(.WITH_CSR(0), .RESET_PC(32'h00000000)) serv(
        .clk(clk),
        .i_rst(rst),
        .i_timer_irq(1'b0),

        // Register File
        .o_rf_rreq(rf_rreq),
        .o_rf_wreq(rf_wreq),
        .i_rf_ready(rf_ready),
        .o_wreg0(rf_wreg0),
        .o_wen0(rf_wen0),
        .o_wdata0(rf_wdata0),
        .o_rreg0(rf_rreg0),
        .o_rreg1(rf_rreg1),
        .i_rdata0(rf_rdata0),
        .i_rdata1(rf_rdata1),

        // Instruction bus
        .o_ibus_adr(ibus_adr),
        .o_ibus_cyc(ibus_cyc),
        .i_ibus_rdt(ibus_rdt),
        .i_ibus_ack(ibus_ack),

        // Data bus
        .o_dbus_adr(dbus_adr),
        .o_dbus_dat(dbus_dat),
        .o_dbus_sel(dbus_sel),
        .o_dbus_we(dbus_we),
        .o_dbus_cyc(dbus_cyc),
        .i_dbus_rdt(dbus_rdt),
        .i_dbus_ack(dbus_ack),

        // Extension interface
        .i_ext_ready(1'b0),
        .i_ext_rd(32'h00000000)
    );
    /* verilator lint_on PINMISSING */
   
    register_file rf(
        .clk(clk),
        .rst(rst),

        .rf_rreq(rf_rreq),
        .rf_wreq(rf_wreq),
        .rf_ready(rf_ready),
        .rf_wen0(rf_wen0),
        .rf_wreg0(rf_wreg0[3:0]),
        .rf_wdata0(rf_wdata0),
        .rf_rreg0(rf_rreg0[3:0]),
        .rf_rdata0(rf_rdata0),
        .rf_rreg1(rf_rreg1[3:0]),
        .rf_rdata1(rf_rdata1)
    );

    servile_arbiter arbiter(
        .i_wb_cpu_dbus_adr(dbus_adr),
        .i_wb_cpu_dbus_dat(dbus_dat),
        .i_wb_cpu_dbus_sel(dbus_sel),
        .i_wb_cpu_dbus_we(dbus_we),
        .i_wb_cpu_dbus_stb(dbus_cyc),
        .o_wb_cpu_dbus_rdt(dbus_rdt),
        .o_wb_cpu_dbus_ack(dbus_ack),

        .i_wb_cpu_ibus_adr(ibus_adr),
        .i_wb_cpu_ibus_stb(ibus_cyc),
        .o_wb_cpu_ibus_rdt(ibus_rdt),
        .o_wb_cpu_ibus_ack(ibus_ack),

        .o_wb_mem_adr(wb_adr),
        .o_wb_mem_dat(wb_dat),
        .o_wb_mem_sel(wb_sel),
        .o_wb_mem_we(wb_we),
        .o_wb_mem_stb(wb_stb),
        .i_wb_mem_rdt(wb_rdt),
        .i_wb_mem_ack(wb_ack | wb_rty | wb_err)
    );
endmodule
