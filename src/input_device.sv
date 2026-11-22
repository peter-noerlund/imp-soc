`default_nettype none

module input_device
    #(
        parameter int ADDR_WIDTH=32,
        parameter int DATA_WIDTH=32
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

        input wire [7:0] input_pmod
    );

    wire [23:0] gamepad_state;
    wire [7:0] raw_state;

    bit ack;

    bit [23:0] gamepad_shift;
    bit [23:0] gamepad_mem;
    bit prev_gamepad_clk;
    bit prev_gamepad_latch;

    wire gamepad_latch;
    wire gamepad_clk;
    wire gamepad_data;

    bit latch;

    assign wb_ack = &{wb_cyc, wb_stb, ack};
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;
    assign wb_rdt = {raw_state, gamepad_state};

    assign raw_state = input_pmod;

    assign gamepad_latch = input_pmod[4];
    assign gamepad_clk = input_pmod[5];
    assign gamepad_data = input_pmod[6];

    assign gamepad_state = gamepad_mem;

    always_ff @ (posedge clk) begin
        if (rst) begin
            gamepad_shift <= 24'hFFFFFF;
            prev_gamepad_clk <= 1'b0;
            prev_gamepad_latch <= 1'b0;
            latch <= 1'b0;
        end else begin
            prev_gamepad_clk <= gamepad_clk;
            prev_gamepad_latch <= gamepad_latch;

            latch <= gamepad_latch && !prev_gamepad_latch;

            if (gamepad_clk && !prev_gamepad_clk) begin
                gamepad_shift <= {gamepad_shift[23:0], gamepad_data};
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (latch) begin
            gamepad_mem <= gamepad_shift;
        end
    end

    always_ff @ (posedge clk) begin
        ack <= ~rst & wb_cyc & wb_stb & ~ack;
    end

    wire _unused = &{wb_adr, wb_we, wb_sel, wb_dat, wb_cti, wb_bte};
endmodule
