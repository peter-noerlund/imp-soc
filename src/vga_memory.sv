`default_nettype none

/**
VGA Memory

Managed frame buffer for VGA device.

Internally, it stores a number of words, denoted at line.

When `read_line` is asserted, it fetches the next line.

The line size is defined by `WORD_COUNT`, but the actual line length on the wishbone bus is rounded up to nearest modulo 2.

After `LINE_COUNT` lines, it resets
*/
module vga_memory
    #(
        parameter int ADDR_WIDTH=32,
        parameter int WORD_COUNT=16,
        parameter int WORD_SIZE=24,
        parameter int LINE_COUNT=96
    )
    (
        input wire clk,
        input wire rst,

        /* verilator lint_off UNUSEDSIGNAL */
        input wire [ADDR_WIDTH - 1 : 0] vgaconfig_addr, //! Base address
        /* verilator lint_on UNUSEDSIGNAL */

        input wire vgactrl_read_req,                            //! Read line request
        output wire [WORD_COUNT * WORD_SIZE - 1 : 0] vgactrl_memory,   //! Memory

        //! @virtualbus WB @dir output Wishbone bus
        output wire wb_cyc,                             //! Wishbone signal CYC_O
        output wire wb_stb,                             //! Wishbone signal STB_O
        output wire [ADDR_WIDTH - 1 : 0] wb_adr,        //! Wishbone signal ADR_O
        output wire wb_we,                              //! Wishbone signal WE_O
        output wire [3:0] wb_sel,                       //! Wishbone signal SEL_O
        output wire [2:0] wb_cti,                       //! Wishbone signal CTI_O
        output wire [1:0] wb_bte,                       //! Wishbone signal BTE_O
        output wire [31:0] wb_dat,                      //! Wishbone signal DAT_O
        input wire wb_ack,                              //! Wishbone signal ACK_I
        input wire wb_rty,                              //! Wishbone signal RTY_I
        input wire wb_err,                              //! Wishbone signal ERR_I
        /* verilator lint_off UNUSEDSIGNAL */
        input wire [31:0] wb_rdt                        //! Wishbone signal DAT_I
        /* verilator lint_on UNUSEDSIGNAL */
        //! @end
    );

    localparam [2:0] CTI_INCREMENT = 3'b010;
    localparam [2:0] CTI_END_OF_BURST = 3'b111;

    localparam [1:0] BTE_LINEAR = 2'b00;

    localparam int WORD_WIDTH = $clog2(WORD_COUNT);
    localparam int LINE_WIDTH = $clog2(LINE_COUNT);

    bit [WORD_WIDTH - 1 : 0] word_idx;
    bit [LINE_WIDTH - 1 : 0] line_idx;

    bit [WORD_SIZE - 1 : 0] buffer;
    bit latch0;
    bit latch1;
    
    bit cyc;
    wire ack;
    wire last_word;

    wire [WORD_COUNT * WORD_SIZE - 1 : 0] memory;

    genvar i;

    assign wb_cyc = cyc;
    assign wb_stb = cyc;
    assign wb_adr = {vgaconfig_addr[ADDR_WIDTH - 1 : LINE_WIDTH + WORD_WIDTH + 2], line_idx, word_idx, 2'b00};
    assign wb_we = 1'b0;
    assign wb_sel = 4'b1111;
    assign wb_cti = word_idx == WORD_WIDTH'(WORD_COUNT - 1) ? CTI_END_OF_BURST : CTI_INCREMENT;
    assign wb_bte = BTE_LINEAR;
    assign wb_dat = 32'h00000000;
    assign ack = cyc & (wb_ack | wb_rty | wb_err);
    assign last_word = word_idx == WORD_WIDTH'(WORD_COUNT - 1);

    assign vgactrl_memory = {memory[WORD_SIZE - 1 : 0], memory[WORD_COUNT * WORD_SIZE - 1 : WORD_SIZE]};

    // Word index
    always_ff @ (posedge clk) begin
        if (rst) begin
            word_idx <= WORD_WIDTH'(0);
        end else if (ack) begin
            if (last_word) begin
                word_idx <= WORD_WIDTH'(0);
            end else begin
                word_idx <= word_idx + WORD_WIDTH'(1);
            end
        end
    end

    // Line index
    always_ff @ (posedge clk) begin
        if (rst) begin
            line_idx <= LINE_WIDTH'(1);
        end else if (ack && last_word) begin
            if (line_idx == LINE_WIDTH'(LINE_COUNT - 1)) begin
                line_idx <= LINE_WIDTH'(0);
            end else begin
                line_idx <= line_idx + LINE_WIDTH'(1);
            end
        end
    end

    // Cyc
    always_ff @ (posedge clk) begin
        if (rst) begin
            cyc <= 1'b0;
        end else begin
            if (!cyc && vgactrl_read_req) begin
                cyc <= 1'b1;
            end else if (ack && last_word) begin
                cyc <= 1'b0;
            end
        end
    end

    // Buffer
    always_ff @ (posedge clk) begin
        if (!rst && ack) begin
            // Byte layout is 00rrggbb 00RRGGBB 0bbb0aaa 0ddd0ccc whish translates to 0ddd0ccc_0bbb0aaa_00RRGGBB_00rrggbb
            // VGA renderer expects rrggbb_RRGGBB_ddd_ccc_bbb_aaa
            // TODO - Should the hardware convert 4 bits to 3 bit?
            buffer <= {
                wb_rdt[5:0],    // color 1
                wb_rdt[13:8],   // color 2
                wb_rdt[30:28],  // pixel group 4 (pixel 7 and 8)
                wb_rdt[26:24],  // pixel group 3 (pixel 5 and 6)
                wb_rdt[22:20],  // pixel group 2 (pixel 3 and 4)
                wb_rdt[18:16]   // pixel group 1 (pixel 1 and 2)
            };
        end
    end

    // Latch0
    always_ff @ (posedge clk) begin
        latch0 <= !rst & ack;
    end

    // Latch1
    always_ff @ (negedge clk) begin
        latch1 <= latch0;
    end

    // Memory
    generate
        for (i = 0; i != WORD_COUNT; i++) begin: mem_n
            vga_latch #(.WIDTH(WORD_SIZE)) mem(.clk(clk), .gate(latch1 && word_idx == WORD_WIDTH'(i)), .data_in(buffer), .data_out(memory[i * WORD_SIZE + WORD_SIZE - 1 -: WORD_SIZE]));
        end
    endgenerate


endmodule
