`default_nettype none

module timer_device
    #(
        parameter int ADDR_WIDTH=32,
        parameter int DATA_WIDTH=32,
        parameter int COUNTER_WIDTH=DATA_WIDTH
    )
    (
        input wire clk,
        input wire rst,

        input wire wb_cyc,
        input wire wb_stb,
        input wire [ADDR_WIDTH - 1 : 0] wb_adr,
        input wire wb_we,
        input wire [(DATA_WIDTH / 8) - 1 : 0] wb_sel,
        input wire [DATA_WIDTH - 1 : 0] wb_dat,
        input wire [2:0] wb_cti,
        input wire [1:0] wb_bte,
        output wire wb_ack,
        output wire wb_rty,
        output wire wb_err,
        output wire [DATA_WIDTH - 1 : 0] wb_rdt,

        output wire irq_out
    );

    bit [COUNTER_WIDTH - 1 : 0] counter;
    bit irq;

    bit ack;

    assign wb_ack = &{wb_cyc, wb_stb, ack};
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;
    assign wb_rdt = DATA_WIDTH'(0);

    assign irq_out = irq;

    always_ff @ (posedge clk) begin
        if (rst) begin
            counter <= COUNTER_WIDTH'(0);
        end else if (wb_cyc & wb_stb & wb_we & ~ack) begin
            counter <= wb_dat[COUNTER_WIDTH - 1 : 0];
        end else if (counter != COUNTER_WIDTH'(0)) begin
            counter <= counter - COUNTER_WIDTH'(1);
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            irq <= 1'b0;
        end else if (wb_cyc & wb_stb & wb_we & ~ack) begin
            irq <= 1'b0;
        end else if (counter == COUNTER_WIDTH'(1)) begin
            irq <= 1'b1;
        end
    end

    always_ff @ (posedge clk) begin
        ack <= ~rst & wb_cyc & wb_stb & ~ack;
    end

    wire _unused = &{wb_adr, wb_sel, wb_cti, wb_bte};

    generate
        if (DATA_WIDTH > COUNTER_WIDTH) begin: gen_unused_dat
            wire _unused_dat = &{wb_dat[DATA_WIDTH - 1 : COUNTER_WIDTH]};
        end
    endgenerate
endmodule

