`default_nettype none

module audio_device
    #(
        parameter int ADDR_WIDTH=32,
        parameter int DATA_WIDTH=32,
        parameter int COUNTER_WIDTH=DATA_WIDTH,
        parameter int RESET_VALUE_WIDTH=COUNTER_WIDTH
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

        output wire audio_out
    );

    localparam int PAD_WIDTH = COUNTER_WIDTH - RESET_VALUE_WIDTH;

    bit [COUNTER_WIDTH - 1 : 0] counter;
    bit [RESET_VALUE_WIDTH - 1 : 0] reset_value_mem;
    bit audio;
    bit ack;

    wire [COUNTER_WIDTH - 1 : 0] reset_value;

    assign wb_ack = &{wb_cyc, wb_stb, ack};
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;
    assign wb_rdt = DATA_WIDTH'(0);

    assign audio_out = audio;

    generate
        if (COUNTER_WIDTH > RESET_VALUE_WIDTH) begin: gen_reset_value_pad
            assign reset_value = {reset_value_mem, PAD_WIDTH'(0)};
        end else begin: gen_reset_value_nopad
            assign reset_value = reset_value_mem;
        end
    endgenerate

    always_ff @ (posedge clk) begin
        if (rst) begin
            counter <= COUNTER_WIDTH'(0);
        end else begin
            if (counter == COUNTER_WIDTH'(0)) begin
                counter <= reset_value;
            end else begin
                counter <= counter - COUNTER_WIDTH'(1);
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            audio <= 1'b1;
        end else if (counter == COUNTER_WIDTH'(0) && reset_value != COUNTER_WIDTH'(0)) begin
            audio <= ~audio;
        end
    end

    always_ff @ (posedge clk) begin
        ack <= ~rst & wb_cyc & wb_stb;
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            reset_value_mem <= RESET_VALUE_WIDTH'(0);
        end else if (wb_cyc & wb_stb & wb_we & ~ack) begin
            reset_value_mem <= wb_dat[RESET_VALUE_WIDTH - 1 : 0];
        end
    end

    wire _unused = &{wb_adr, wb_sel, wb_cti, wb_bte};

    generate
        if (DATA_WIDTH > RESET_VALUE_WIDTH) begin: gen_unused_dat1
            wire _unused_dat1 = &{wb_dat[DATA_WIDTH - 1 : RESET_VALUE_WIDTH]};
        end
    endgenerate
endmodule

