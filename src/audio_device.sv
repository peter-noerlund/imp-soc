`default_nettype none

module audio_device
    #(
        parameter int ADDR_WIDTH=32,
        parameter int DATA_WIDTH=32,
        parameter int COUNTER_WIDTH=32,
        parameter int REGISTER_WIDTH=COUNTER_WIDTH,
        parameter [0:0] RETURN_REGISTER=0
    )
    (
        input wire clk,
        input wire rst,

        input wire wb_cyc,
        input wire wb_stb,
        input wire [ADDR_WIDTH - 1 : 0] wb_adr,
        input wire wb_we,
        /* verilator lint_off UNUSEDSIGNAL */
        input wire [(DATA_WIDTH / 8) - 1 : 0] wb_sel,
        input wire [DATA_WIDTH - 1 : 0] wb_dat,
        input wire [2:0] wb_cti,
        input wire [1:0] wb_bte,
        /* verilator lint_on UNUSEDSIGNAL */
        output wire wb_ack,
        output wire wb_rty,
        output wire wb_err,
        output wire [DATA_WIDTH - 1 : 0] wb_rdt,

        output wire audio_out
    );

    localparam int PAD_WIDTH = COUNTER_WIDTH - REGISTER_WIDTH;


    bit [COUNTER_WIDTH - 1 : 0] counter;
    bit [REGISTER_WIDTH - 1 : 0] register;
    bit state;
    bit ack;
    
    wire [COUNTER_WIDTH - 1 : 0] reset_value;

    assign wb_ack = &{wb_cyc, wb_stb, ack};
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;

    assign audio_out = state;

    generate
        if (COUNTER_WIDTH > REGISTER_WIDTH) begin: small_reg
            assign reset_value = {register, PAD_WIDTH'(0)};
        end else begin: large_reg
            assign reset_value = register;
        end
    endgenerate

    generate
        if (RETURN_REGISTER) begin: return_reg
            assign wb_rdt = DATA_WIDTH'(register);
        end else begin: return_cnt
            assign wb_rdt = DATA_WIDTH'(counter);
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
            state <= 1'b1;
        end else if (counter == COUNTER_WIDTH'(0) && register != REGISTER_WIDTH'(0)) begin
            state <= ~state;
        end
    end            

    always_ff @ (posedge clk) begin
        if (rst) begin
            register <= COUNTER_WIDTH'(0);
        end else begin
            if (wb_cyc && wb_stb && wb_we) begin
                register <= wb_dat[COUNTER_WIDTH - 1 : 0];
            end
        end
    end

    always_ff @ (posedge clk) begin
        ack <= ~rst & wb_cyc & wb_stb & ~ack;
    end
endmodule
