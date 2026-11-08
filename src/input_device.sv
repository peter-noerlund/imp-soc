`default_nettype none

module input_device
    #(
        parameter int ADDR_WIDTH=32,
        parameter int DATA_WIDTH=32,
        parameter [1:0] GAMEPAD_COUNT=2,
        parameter [0:0] ENABLE_RAW_INPUT=0
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

    assign wb_ack = &{wb_cyc, wb_stb, ack};
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;
    assign wb_rdt = {raw_state, gamepad_state};

    generate
        if (ENABLE_RAW_INPUT) begin: raw_input1
            assign raw_state = input_pmod;
        end else begin: no_raw_input
            assign raw_state = 8'b00000000;
        end
    endgenerate

    generate
        if (GAMEPAD_COUNT == 0) begin: no_gamepad
            assign gamepad_state = 24'hFFFFFF;
        end else begin: gamepad
            localparam int STATE_WIDTH = GAMEPAD_COUNT * 12;

            bit [STATE_WIDTH - 1 : 0] gamepad_shift;
            bit [STATE_WIDTH - 1 : 0] gamepad_mem;

            bit prev_gamepad_clk;
            bit prev_gamepad_latch;

            wire gamepad_latch;
            wire gamepad_clk;
            wire gamepad_data;

            bit latch;

            assign gamepad_latch = input_pmod[4];
            assign gamepad_clk = input_pmod[5];
            assign gamepad_data = input_pmod[6];

            if (GAMEPAD_COUNT == 1) begin: one_gamepad
                assign gamepad_state = {gamepad_mem, 12'hFFF};
            end else begin: two_gamepads
                assign gamepad_state = gamepad_mem;
            end

            always_ff @ (posedge clk) begin
                if (rst) begin
                    gamepad_shift <= STATE_WIDTH'(1);
                    prev_gamepad_clk <= 1'b0;
                    prev_gamepad_latch <= 1'b0;
                    latch <= 1'b0;
                end else begin
                    prev_gamepad_clk <= gamepad_clk;
                    prev_gamepad_latch <= gamepad_latch;

                    latch <= gamepad_latch && !prev_gamepad_latch;

                    if (gamepad_clk && !prev_gamepad_clk) begin
                        gamepad_shift <= {gamepad_shift[STATE_WIDTH - 2 : 0], gamepad_data};
                    end
                end
            end

            always_ff @ (posedge clk) begin
                if (latch) begin
                    gamepad_mem <= gamepad_shift;
                end
            end
        end
    endgenerate

    always_ff @ (posedge clk) begin
        ack <= ~rst & wb_cyc & wb_stb & ~ack;
    end

    wire _unused = &{wb_adr, wb_we, wb_sel, wb_dat, wb_cti, wb_bte};

    generate
        if (!ENABLE_RAW_INPUT) begin: gen_unused_raw_input
            wire _unused_raw_input = &{input_pmod[7], input_pmod[3:0]};
        end
        if (GAMEPAD_COUNT == 0 && !ENABLE_RAW_INPUT) begin: gen_unused_gamepad
            wire _unused_gamepad = &{input_pmod[5:4]};
        end
    endgenerate
endmodule
