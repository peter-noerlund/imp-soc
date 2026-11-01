`default_nettype none

module wb_interconnect
    #(
        parameter ADDR_WIDTH=32,                    //! Address width
        parameter DATA_WIDTH=32                     //! Data width
    )
    (
        //! @virtualbus WB_IN @dir input Wishbone input bus
        input wire wb_in_stb,                           //! Wishbone signal STB_I
        /* verilator lint_off UNUSEDSIGNAL */
        input wire [ADDR_WIDTH - 1 : 0] wb_in_adr,      //! Wishbone signal ADR_I
        /* verilator lint_on UNUSEDSIGNAL */
        output wire wb_in_ack,                          //! Wishbone signal ACK_O
        output wire wb_in_err,                          //! Wishbone signal ERR_O
        output wire wb_in_rty,                          //! Wishbone signal RTY_O
        output wire [DATA_WIDTH - 1 : 0] wb_in_rdt,     //! Wishbone signal DAT_O
        //! @end

        //! @virtualbus WB_MEM @dir output Wishbone signals for memory device
        output wire wb_mem_stb,                        //! Wishbone signal STB_O
        input wire wb_mem_ack,                         //! Wishbone signal ACK_I
        input wire wb_mem_err,                         //! Wishbone signal ERR_I
        input wire wb_mem_rty,                         //! Wishbone signal RTY_I
        input wire [DATA_WIDTH - 1 : 0] wb_mem_rdt,    //! Wishbone signal DAT_I
        //! @end

        //! @virtualbus WB_CLOCK @dir output Wishbone signals for clock device
        output wire wb_clock_stb,                        //! Wishbone signal STB_O
        input wire wb_clock_ack,                         //! Wishbone signal ACK_I
        input wire wb_clock_err,                         //! Wishbone signal ERR_I
        input wire wb_clock_rty,                         //! Wishbone signal RTY_I
        input wire [DATA_WIDTH - 1 : 0] wb_clock_rdt,    //! Wishbone signal DAT_I
        //! @end

        //! @virtualbus WB_UART @dir output Wishbone signals for UART device
        output wire wb_uart_stb,                        //! Wishbone signal STB_O
        input wire wb_uart_ack,                         //! Wishbone signal ACK_I
        input wire wb_uart_err,                         //! Wishbone signal ERR_I
        input wire wb_uart_rty,                         //! Wishbone signal RTY_I
        input wire [DATA_WIDTH - 1 : 0] wb_uart_rdt,   //! Wishbone signal DAT_I
        //! @end

        //! @virtualbus WB_VGA @dir output Wishbone signals for UART device
        output wire wb_vga_stb,                        //! Wishbone signal STB_O
        input wire wb_vga_ack,                         //! Wishbone signal ACK_I
        input wire wb_vga_err,                         //! Wishbone signal ERR_I
        input wire wb_vga_rty,                         //! Wishbone signal RTY_I
        input wire [DATA_WIDTH - 1 : 0] wb_vga_rdt    //! Wishbone signal DAT_I
        //! @end
    );

    wire mem_sel;
    wire clock_sel;
    wire uart_sel;
    wire vga_sel;

    assign mem_sel = wb_in_adr[25] == 1'b0;                                 // Memory at 0x00000000 - 0x01FFFFFF (xxxx_xx0x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx)
    assign clock_sel = wb_in_adr[25] == 1'b1 && wb_in_adr[3:2] == 2'b00;    // Clock  at 0x02000000 - 0x02000003 (xxxx_xx1x_xxxx_xxxx_xxxx_xxxx_xxxx_00xx)
    assign uart_sel = wb_in_adr[25] == 1'b1 && wb_in_adr[3:2] == 2'b01;     // UART   at 0x02000004 - 0x02000007 (xxxx_xx1x_xxxx_xxxx_xxxx_xxxx_xxxx_01xx)
    assign vga_sel = wb_in_adr[25] == 1'b1 && wb_in_adr[3] == 1'b1;         // Video  at 0x02000008 - 0x0200000F (xxxx_xx1x_xxxx_xxxx_xxxx_xxxx_xxxx_1xxx)

    assign wb_mem_stb = wb_in_stb & mem_sel;
    assign wb_clock_stb = wb_in_stb & clock_sel;
    assign wb_uart_stb = wb_in_stb & uart_sel;
    assign wb_vga_stb = wb_in_stb & vga_sel;

    assign wb_in_ack = wb_mem_ack | wb_clock_ack | wb_uart_ack | wb_vga_ack;
    assign wb_in_err = wb_mem_err | wb_clock_err | wb_uart_err | wb_vga_err;
    assign wb_in_rty = wb_mem_rty | wb_clock_rty | wb_uart_rty | wb_vga_rty;

    assign wb_in_rdt =
        mem_sel ? wb_mem_rdt :
        clock_sel ? wb_clock_rdt :
        uart_sel ? wb_uart_rdt :
        wb_vga_rdt;
endmodule
