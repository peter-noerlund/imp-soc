`default_nettype none

module init_qspi_pmod
    (
        input wire clk,
        input wire rst,

        output wire spi_sck,
        output wire spi_flash_ss_n,
        output wire spi_psram_ss_n,
        output wire [3:0] spi_sio_oe,
        output wire [3:0] spi_sio_out,

        output wire done
    );

    bit [8:0] prog [63:0];
    bit [5:0] counter;

    bit [8:0] instr;

    bit done_r;

    assign spi_sck = instr[8];
    assign spi_flash_ss_n = instr[7];
    assign spi_psram_ss_n = instr[6];
    assign spi_sio_oe = {instr[5], instr[5], instr[5], instr[4]};
    assign spi_sio_out = instr[3:0];

    assign done = done_r;

    always_comb begin
        prog[0]  = 9'b0_1_1_0_0_0000;
        // Flash
        // Quad read command (0xEB)
        prog[1]  = 9'b0_0_1_0_1_0001;
        prog[2]  = 9'b1_0_1_0_1_0001;
        prog[3]  = 9'b0_0_1_0_1_0001;
        prog[4]  = 9'b1_0_1_0_1_0001;
        prog[5]  = 9'b0_0_1_0_1_0001;
        prog[6]  = 9'b1_0_1_0_1_0001;
        prog[7]  = 9'b0_0_1_0_1_0000;
        prog[8]  = 9'b1_0_1_0_1_0000;
        prog[9]  = 9'b0_0_1_0_1_0001;
        prog[10] = 9'b1_0_1_0_1_0001;
        prog[11] = 9'b0_0_1_0_1_0000;
        prog[12] = 9'b1_0_1_0_1_0000;
        prog[13] = 9'b0_0_1_0_1_0001;
        prog[14] = 9'b1_0_1_0_1_0001;
        prog[15] = 9'b0_0_1_0_1_0001;
        prog[16] = 9'b1_0_1_0_1_0001;
        // Address=0
        prog[17] = 9'b0_0_1_1_1_0000;
        prog[18] = 9'b1_0_1_1_1_0000;
        prog[19] = 9'b0_0_1_1_1_0000;
        prog[20] = 9'b1_0_1_1_1_0000;
        prog[21] = 9'b0_0_1_1_1_0000;
        prog[22] = 9'b1_0_1_1_1_0000;
        prog[23] = 9'b0_0_1_1_1_0000;
        prog[24] = 9'b1_0_1_1_1_0000;
        prog[25] = 9'b0_0_1_1_1_0000;
        prog[26] = 9'b1_0_1_1_1_0000;
        prog[27] = 9'b0_0_1_1_1_0000;
        prog[28] = 9'b1_0_1_1_1_0000;
        // M[7:0]
        prog[29] = 9'b0_0_1_1_1_0010;
        prog[30] = 9'b1_0_1_1_1_0010;
        prog[31] = 9'b0_0_1_1_1_0000;
        prog[32] = 9'b1_0_1_1_1_0000;
        // Dummy
        prog[33] = 9'b0_0_1_0_0_0000;
        prog[34] = 9'b1_0_1_0_0_0000;
        prog[35] = 9'b0_0_1_0_0_0000;
        prog[36] = 9'b1_0_1_0_0_0000;
        prog[37] = 9'b0_0_1_0_0_0000;
        prog[38] = 9'b1_0_1_0_0_0000;
        prog[39] = 9'b0_0_1_0_0_0000;
        prog[40] = 9'b1_0_1_0_0_0000;
        // Data
        prog[41] = 9'b0_0_1_0_0_0000;
        prog[42] = 9'b1_0_1_0_0_0000;
        prog[43] = 9'b0_0_1_0_0_0000;
        prog[44] = 9'b1_0_1_0_0_0000;
        // Stop
        prog[45] = 9'b0_1_1_0_0_0000;
        prog[46] = 9'b0_1_1_0_0_0000;
        // PSRAM
        // Enter Quad Mode (0x35)
        prog[47] = 9'b0_1_0_0_1_0000;
        prog[48] = 9'b1_1_0_0_1_0000;
        prog[49] = 9'b0_1_0_0_1_0000;
        prog[50] = 9'b1_1_0_0_1_0000;
        prog[51] = 9'b0_1_0_0_1_0001;
        prog[52] = 9'b1_1_0_0_1_0001;
        prog[53] = 9'b0_1_0_0_1_0001;
        prog[54] = 9'b1_1_0_0_1_0001;
        prog[55] = 9'b0_1_0_0_1_0000;
        prog[56] = 9'b1_1_0_0_1_0000;
        prog[57] = 9'b0_1_0_0_1_0001;
        prog[58] = 9'b1_1_0_0_1_0001;
        prog[59] = 9'b0_1_0_0_1_0000;
        prog[60] = 9'b1_1_0_0_1_0000;
        prog[61] = 9'b0_1_0_0_1_0001;
        prog[62] = 9'b1_1_0_0_1_0001;
        prog[63] = 9'b0_1_1_0_0_0000;
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            counter <= 6'd0;
            instr <= 9'b0_1_1_0_0_0000;
            done_r <= 1'b0;
        end else if (!done_r) begin
            counter <= counter + 6'd1;
            instr <= prog[counter];
            if (counter == 6'd63) begin
                done_r <= 1'b1;
            end
        end
    end
endmodule
