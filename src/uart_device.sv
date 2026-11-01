`default_nettype none

module uart_device
    #(
        parameter PERIOD=25,                            //! Period in cycles
        parameter ADDR_WIDTH=32,                        //! Address width
        parameter DATA_WIDTH=32                         //! Data width
    )
    (
        input wire clk,
        input wire rst,

        //! @virtualbus WB @dir input Wishbone bus
        input wire wb_cyc,                              //! Wishbone CYC_I
        input wire wb_stb,                              //! Wishbone STB_I
        input wire [ADDR_WIDTH - 1 : 0] wb_adr,                       //! Wishbone ADR_I
        input wire wb_we,                               //! Wishbone WE_I
        input wire [(DATA_WIDTH / 8) - 1 : 0] wb_sel,   //! Wishbone SEL_I
        input wire [DATA_WIDTH - 1 : 0] wb_dat,         //! Wishbone DAT_I
        input wire [2:0] wb_cti,                        //! Wishbone CTI_I
        input wire [1:0] wb_bte,                        //! Wishbone BTE_I
        output wire wb_ack,                             //! Wishbone ACK_O
        output wire wb_rty,                             //! Wishbone RTY_O
        output wire wb_err,                             //! Wishbone ERR_O
        output wire [DATA_WIDTH - 1 : 0] wb_rdt,        //! Wishbone DAT_O
        //! @end

        output wire uart_tx                             //! UART transmit
    );

    localparam PERIOD_BITS = $clog2(PERIOD) + 1;

    bit ack;
    bit tx;
    bit [PERIOD_BITS - 1 : 0] cnt;
    bit [3:0] bit_pos;

    assign wb_ack = ack && !rst && wb_cyc && wb_stb;
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;
    assign wb_rdt = DATA_WIDTH'(0);
    assign uart_tx = tx;

    always_ff @ (posedge clk) begin
        if (rst || !wb_cyc || !wb_stb) begin
            ack <= 1'b0;
            tx <= 1'b1;
            cnt <= PERIOD_BITS'(0);
            bit_pos <= 4'd0;
        end else begin
            if (wb_we && !ack) begin
                if (cnt == PERIOD) begin
                    cnt <= PERIOD_BITS'(0);
                    bit_pos <= bit_pos + 4'd1;
                end else begin
                    cnt <= cnt + PERIOD_BITS'(1);
                end

                if (cnt == 0) begin
                    case (bit_pos)
                        4'd0: tx <= 1'b0;   // Start bit
                        4'd1: tx <= wb_dat[0];
                        4'd2: tx <= wb_dat[1];
                        4'd3: tx <= wb_dat[2];
                        4'd4: tx <= wb_dat[3];
                        4'd5: tx <= wb_dat[4];
                        4'd6: tx <= wb_dat[5];
                        4'd7: tx <= wb_dat[6];
                        4'd8: tx <= wb_dat[7];
                        4'd9: tx <= 1'b1;   // Stop bit
                        4'd10: begin
                            ack <= 1'b1;
                            cnt <= PERIOD_BITS'(0);
                            bit_pos <= 4'd0;
                        end
                        default: begin
                        end
                    endcase
                end
            end else begin
                ack <= ~ack;
            end
        end
    end
endmodule
