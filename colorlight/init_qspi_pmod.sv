`default_nettype none

module init_qspi_pmod
    (
        input wire clk25,

        output wire LED,
        inout wire [7:0] P3_PMOD2
    );

    // flash_cs psram_cs quad_oe oe sio[3:0]

    bit [7:0] prog [32:0];
    bit [6:0] counter;
    bit [7:0] instr;
    bit done;

    wire clk;
    wire clk_locked;
    wire rst;

    wire [5:0] pc;

    wire spi_sck;
    wire spi_flash_ss_n;
    wire spi_psram_ss_n;
    wire [3:0] spi_sio_out;
    wire [3:0] spi_sio_oe;

    wire [7:0] p3_pmod2_in;
    wire [7:0] p3_pmod2_oe;
    wire [7:0] p3_pmod2_out;

    assign pc = counter[6:1];

    assign spi_sck = counter[0];
    assign spi_flash_ss_n = instr[7];
    assign spi_psram_ss_n = instr[6];
    assign spi_sio_oe = {instr[5], instr[5], instr[5], instr[4]};
    assign spi_sio_out = instr[3:0];

    assign p3_pmod2_oe = {2'b11, spi_sio_oe[3:2], 1'b1, spi_sio_oe[1:0], 1'b1};
    assign p3_pmod2_out = {
        1'b1,
        spi_psram_ss_n,
        spi_sio_out[3:2],
        spi_sck,
        spi_sio_out[1:0],
        spi_flash_ss_n
    };

    assign LED = ~done;

    pll pll(
        .clkin(clk25),
        .clkout0(clk),
        .locked(clk_locked)
    );

    reset_handler reset_handler(
        .clk(clk),
        .clk_locked(clk_locked),
        .rst_out(rst)
    );

    BB bb[7:0] (
        .B(P3_PMOD2),
        .O(p3_pmod2_in),
        .T(~p3_pmod2_oe),
        .I(p3_pmod2_out)
    );

    always_comb begin
        prog[0] = 8'b1_1_0_0_0000;
        // Flash
        // Quad read command (0xEB)
        prog[1] = 8'b0_1_0_1_0001;
        prog[2] = 8'b0_1_0_1_0001;
        prog[3] = 8'b0_1_0_1_0001;
        prog[4] = 8'b0_1_0_1_0000;
        prog[5] = 8'b0_1_0_1_0001;
        prog[6] = 8'b0_1_0_1_0000;
        prog[7] = 8'b0_1_0_1_0001;
        prog[8] = 8'b0_1_0_1_0001;
        // Address=0
        prog[9] = 8'b0_1_1_1_0000;
        prog[10] = 8'b0_1_1_1_0000;
        prog[11] = 8'b0_1_1_1_0000;
        prog[12] = 8'b0_1_1_1_0000;
        prog[13] = 8'b0_1_1_1_0000;
        prog[14] = 8'b0_1_1_1_0000;
        // M[7:0]
        prog[15] = 8'b0_1_1_1_0010;
        prog[16] = 8'b0_1_1_1_0000;
        // Dummy
        prog[17] = 8'b0_1_0_0_0000;
        prog[18] = 8'b0_1_0_0_0000;
        prog[19] = 8'b0_1_0_0_0000;
        prog[20] = 8'b0_1_0_0_0000;
        // Data
        prog[21] = 8'b0_1_0_0_0000;
        prog[22] = 8'b0_1_0_0_0000;
        // Stop
        prog[23] = 8'b1_1_0_0_0000;
        // PSRAM
        // Enter Quad Mode (0x35)
        prog[24] = 8'b1_0_0_1_0000;
        prog[25] = 8'b1_0_0_1_0000;
        prog[26] = 8'b1_0_0_1_0001;
        prog[27] = 8'b1_0_0_1_0001;
        prog[28] = 8'b1_0_0_1_0000;
        prog[29] = 8'b1_0_0_1_0001;
        prog[30] = 8'b1_0_0_1_0000;
        prog[31] = 8'b1_0_0_1_0001;
        // End
        prog[32] = 8'b1_1_0_0_0000;
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            counter <= 7'd0;
            instr <= 8'b1_1_0_0_0000;
            done <= 1'b0;
        end else if (!done) begin
            if (pc == 6'd32) begin
                done <= 1'b1;
            end else begin
                counter <= counter + 7'd1;
                instr <= prog[pc];
            end
        end
    end
endmodule
