`default_nettype none

module wb_interconnect
    #(
        parameter ADDR_WIDTH=32,                    //! Address width
        parameter DATA_WIDTH=32                     //! Data width
    )
    (
        //! @virtualbus WB_IN @dir input Wishbone input bus
        input wire wb_in_stb,                           //! Wishbone signal STB_I
        input wire [ADDR_WIDTH - 1 : 0] wb_in_adr,      //! Wishbone signal ADR_I
        output wire wb_in_ack,                          //! Wishbone signal ACK_O
        output wire wb_in_err,                          //! Wishbone signal ERR_O
        output wire wb_in_rty,                          //! Wishbone signal RTY_O
        output wire [DATA_WIDTH - 1 : 0] wb_in_rdt,     //! Wishbone signal DAT_O
        //! @end

        //! @virtualbus WB_MEM @dir output Wishbone signals for memory device
        output wire wb_mem_stb,                         //! Wishbone signal STB_O
        input wire wb_mem_ack,                          //! Wishbone signal ACK_I
        input wire wb_mem_err,                          //! Wishbone signal ERR_I
        input wire wb_mem_rty,                          //! Wishbone signal RTY_I
        input wire [DATA_WIDTH - 1 : 0] wb_mem_rdt,     //! Wishbone signal DAT_I
        //! @end

        //! @virtualbus WB_CLOCK @dir output Wishbone signals for timer device
        output wire wb_timer_stb,                       //! Wishbone signal STB_O
        input wire wb_timer_ack,                        //! Wishbone signal ACK_I
        input wire wb_timer_err,                        //! Wishbone signal ERR_I
        input wire wb_timer_rty,                        //! Wishbone signal RTY_I
        input wire [DATA_WIDTH - 1 : 0] wb_timer_rdt,   //! Wishbone signal DAT_I
        //! @end

        //! @virtualbus WB_INPUT @dir output Wishbone signals for input device
        output wire wb_input_stb,                       //! Wishbone signal STB_O
        input wire wb_input_ack,                        //! Wishbone signal ACK_I
        input wire wb_input_err,                        //! Wishbone signal ERR_I
        input wire wb_input_rty,                        //! Wishbone signal RTY_I
        input wire [DATA_WIDTH - 1 : 0] wb_input_rdt,   //! Wishbone signal DAT_I
        //! @end

        //! @virtualbus WB_AUDIO @dir output Wishbone signals for audio device
        output wire wb_audio_stb,                       //! Wishbone signal STB_O
        input wire wb_audio_ack,                        //! Wishbone signal ACK_I
        input wire wb_audio_err,                        //! Wishbone signal ERR_I
        input wire wb_audio_rty,                        //! Wishbone signal RTY_I
        input wire [DATA_WIDTH - 1 : 0] wb_audio_rdt,   //! Wishbone signal DAT_I
        //! @end

        //! @virtualbus WB_VGA @dir output Wishbone signals for VGA device
        output wire wb_vga_stb,                         //! Wishbone signal STB_O
        input wire wb_vga_ack,                          //! Wishbone signal ACK_I
        input wire wb_vga_err,                          //! Wishbone signal ERR_I
        input wire wb_vga_rty,                          //! Wishbone signal RTY_I
        input wire [DATA_WIDTH - 1 : 0] wb_vga_rdt      //! Wishbone signal DAT_I
        //! @end
    );

    wire mem_sel;
    wire timer_sel;
    wire input_sel;
    wire audio_sel;
    wire vga_sel;

    assign mem_sel   = wb_in_adr[25] == 1'b0;                               // Memory at 0x00000000 - 0x01FFFFFF (xxxx_xx0x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx)
    assign timer_sel = wb_in_adr[25] == 1'b1 && wb_in_adr[3:2] == 2'b00;    // Timer  at 0x02000000 - 0x02000007 (xxxx_xx1x_xxxx_xxxx_xxxx_xxxx_xxxx_00xx)
    assign input_sel = wb_in_adr[25] == 1'b1 && wb_in_adr[3:2] == 2'b01;    // Input  at 0x02000008 - 0x0200000F (xxxx_xx1x_xxxx_xxxx_xxxx_xxxx_xxxx_01xx)
    assign audio_sel = wb_in_adr[25] == 1'b1 && wb_in_adr[3:2] == 2'b10;    // Audio  at 0x02000010 - 0x02000017 (xxxx_xx1x_xxxx_xxxx_xxxx_xxxx_xxxx_10xx)
    assign vga_sel   = wb_in_adr[25] == 1'b1 && wb_in_adr[3:2] == 2'b11;    // Video  at 0x02000018 - 0x0200001F (xxxx_xx1x_xxxx_xxxx_xxxx_xxxx_xxxx_11xx)

    assign wb_mem_stb = wb_in_stb & mem_sel;
    assign wb_timer_stb = wb_in_stb & timer_sel;
    assign wb_input_stb = wb_in_stb & input_sel;
    assign wb_audio_stb = wb_in_stb & audio_sel;
    assign wb_vga_stb = wb_in_stb & vga_sel;

    assign wb_in_ack = wb_mem_ack | wb_timer_ack | wb_input_ack | wb_audio_ack | wb_vga_ack;
    assign wb_in_rty = wb_mem_rty | wb_timer_rty | wb_input_rty | wb_audio_rty | wb_vga_rty;
    assign wb_in_err = wb_mem_err | wb_timer_err | wb_input_err | wb_audio_err | wb_vga_err;

    assign wb_in_rdt =
        mem_sel ? wb_mem_rdt :
        timer_sel ? wb_timer_rdt :
        input_sel ? wb_input_rdt :
        audio_sel ? wb_audio_rdt :
        wb_vga_rdt;

    wire _unused = &{wb_in_adr[24:4], wb_in_adr[1:0]};
endmodule
