`default_nettype none

module input_device
    #(
        parameter int ADDR_WIDTH=32,
        parameter int DATA_WIDTH=32,
        parameter int GAMEPAD_COUNT=2,
        parameter [0:0] ENABLE_RAW_INPUT=1
    )
    (
        input wire clk,
        input wire rst,

        input wire wb_cyc,
        input wire wb_stb,
        input wire [ADDR_WIDTH - 1 : 0] wb_adr,
        /* verilator lint_off UNUSEDSIGNAL */
        input wire wb_we,
        input wire [(DATA_WIDTH / 8) - 1 : 0] wb_sel,
        input wire [DATA_WIDTH - 1 : 0] wb_dat,
        input wire [2:0] wb_cti,
        input wire [1:0] wb_bte,
        /* verilator lint_on UNUSEDSIGNAL */
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
        if (ENABLE_RAW_INPUT) begin: raw_input
            bit [7:0] raw_state_reg;

            assign raw_state = raw_state_reg;

            always_ff @ (posedge clk) begin
                raw_state_reg <= input_pmod;
            end
        end else begin: no_raw_input
            assign raw_state = 8'b00000000;
        end
    endgenerate

    generate
        if (GAMEPAD_COUNT == 0) begin: no_gamepad
            assign gamepad_state = 24'hFFFFFF;
        end else begin: gamepad
            localparam int STATE_WIDTH = GAMEPAD_COUNT * 12;

            bit [STATE_WIDTH - 1 : 0] gamepad_state_reg;
            bit [STATE_WIDTH - 1 : 0] gamepad_shift;

            bit prev_gamepad_clk;
            bit prev_gamepad_latch;

            wire gamepad_latch;
            wire gamepad_clk;
            wire gamepad_data;

            assign gamepad_latch = input_pmod[4];
            assign gamepad_clk = input_pmod[5];
            assign gamepad_data = input_pmod[6];

            if (GAMEPAD_COUNT == 1) begin: one_gamepad
                assign gamepad_state = {gamepad_state_reg, 12'hFFF};
            end else begin: two_gamepads
                assign gamepad_state = gamepad_state_reg;
            end

            always_ff @ (posedge clk) begin
                if (rst) begin
                    gamepad_state_reg <= STATE_WIDTH'(1);
                    gamepad_shift <= STATE_WIDTH'(1);
                    prev_gamepad_clk <= 1'b0;
                    prev_gamepad_latch <= 1'b0;
                end else begin
                    prev_gamepad_clk <= gamepad_clk;
                    prev_gamepad_latch <= gamepad_latch;

                    if (gamepad_latch && !prev_gamepad_latch) begin
                        gamepad_state_reg <= gamepad_shift;
                    end

                    if (gamepad_clk && !prev_gamepad_clk) begin
                        gamepad_shift <= {gamepad_shift[STATE_WIDTH - 2 : 0], gamepad_data};
                    end
                end
            end
        end
    endgenerate

    always_ff @ (posedge clk) begin
        ack <= ~rst & wb_cyc & wb_stb & ~ack;
    end
endmodule
