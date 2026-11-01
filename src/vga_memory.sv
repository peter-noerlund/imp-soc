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
        parameter int WORD_COUNT=15,
        parameter int LINE_COUNT=100
    )
    (
        input wire clk,
        input wire rst,

        input wire [ADDR_WIDTH - 1 : 0] vgaconfig_addr, //! Base address
        input wire read_req,                            //! Read line request
        output wire [WORD_COUNT * 32 - 1 : 0] memory,   //! Memory

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
        input wire [31:0] wb_rdt                        //! Wishbone signal DAT_I
        //! @end
    );

    localparam [2:0] CTI_INCREMENT = 3'b010;
    localparam [2:0] CTI_END_OF_BURST = 3'b111;

    localparam [1:0] BTE_LINEAR = 2'b00;

    localparam int WORD_WIDTH = $clog2(WORD_COUNT);
    localparam int LINE_WIDTH = $clog2(LINE_COUNT);

    bit [WORD_COUNT * 32 - 1 : 0] mem;

    bit [WORD_WIDTH - 1 : 0] word_idx;
    bit [LINE_WIDTH - 1 : 0] line_idx;

    bit [31:0] buffer;
    bit latch0;
    bit latch1;
    
    bit cyc;
    wire ack;
    wire last_word;

    genvar i;

    assign wb_cyc = cyc;
    assign wb_stb = cyc;
    assign wb_adr = {vgaconfig_addr[ADDR_WIDTH - 1 : LINE_WIDTH + WORD_WIDTH + 2], line_idx, word_idx, 2'b00};
    assign wb_we = 1'b0;
    assign wb_sel = 4'b1111;
    assign wb_cti = word_idx == WORD_WIDTH'(WORD_COUNT - 2) ? CTI_END_OF_BURST : CTI_INCREMENT;
    assign wb_bte = BTE_LINEAR;
    assign wb_dat = 32'h00000000;
    assign ack = cyc & (wb_ack | wb_rty | wb_err);
    assign last_word = word_idx == WORD_WIDTH'(WORD_COUNT - 1);

    assign memory = mem;

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
            if (!cyc && read_req) begin
                cyc <= 1'b1;
            end
            if (ack && last_word) begin
                cyc <= 1'b0;
            end
        end
    end

    // Buffer
    always_ff @ (posedge clk) begin
        if (!rst && ack) begin
            buffer <= wb_rdt;
        end
    end

    // Latch0
    always_ff @ (posedge clk) begin
        latch0 <= !rst & ack;
    end

    // Latch1
    always_ff @ (posedge clk) begin
        latch1 <= latch0;
    end

    // Memory
`ifdef FPGA
    generate
        for (i = 1; i != WORD_COUNT; ++i) begin
            always_ff @ (posedge clk) begin
                // At this point, word_idx has been incremented, so we need to store the buffer in the previous chunk
                if (latch1 && word_idx == WORD_WIDTH'(i)) begin
                    mem[i * 32 - 1 -: 32] = buffer;
                end
            end
        end
        
        always_ff @ (posedge clk) begin
            if (latch1 && word_idx == WORD_WIDTH'(0)) begin
                mem[WORD_COUNT * 32 - 1 -: 32] = buffer;
            end
        end
    endgenerate
`else // FPGA
    generate
        for (i = 1; i != WORD_COUNT; ++i) begin
            always_latch begin
                // At this point, word_idx has been incremented, so we need to store the buffer in the previous chunk
                if (latch1 && word_idx == WORD_WIDTH'(i)) begin
                    mem[i * 32 - 1 -: 32] = buffer;
                end
            end
        end
        
        always_latch begin
            if (latch1 && word_idx == WORD_WIDTH'(0)) begin
                mem[WORD_COUNT * 32 - 1 -: 32] = buffer;
            end
        end
    endgenerate
`endif // FPGA
endmodule