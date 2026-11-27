`default_nettype none

/**
 * QSPI memory controller
 *
 * Exposes a QSPI-driven flash and PSRAM via a Wishbone bus.
 * The first 16MB goes to the flash and is read only and the last 16MB goes to the PSRAM and is writable.
 * Both flash and PSRAM is expected to support the Fast Quad Read (EB) in 1-4-4 mode with 6 delay cycles,
 * and the PSRAM should support Quad Write (38) in 1-4-4 mode.
 *
 * The byte selection fields m ust be 4'b0001 for byte write, 4'b0011 for two-byte write and 4'b1111 for four-byte write.
 * Use the write_aligner to align the write requests if needed.
 */
module memory_device
    (
        input wire clk,
        input wire rst,

        //! @virtualbus WB @dir input Wishbone bus
        input wire wb_cyc,              //! Wishbone signal CYC_I
        input wire wb_stb,              //! Wishbone signal STB_I
        input wire [24:0] wb_adr,       //! Wishbone signal ADR_I
        input wire wb_we,               //! Wishbone signal WE_I
        input wire [3:0] wb_sel,        //! Wishbone signal SEL_I
        input wire [31:0] wb_dat,       //! Wishbone signal DAT_I
        input wire [2:0] wb_cti,        //! Wishbone signal CTI_I
        input wire [1:0] wb_bte,        //! Wishbone signal BTE_I
        output wire wb_ack,             //! Wishbone signal ACK_O
        output wire wb_err,             //! Wishbone signal ERR_O
        output wire wb_rty,             //! Wishbone signal RTY_O
        output wire [31:0] wb_rdt,      //! Wishbone signal DAT_O
        //! @end

        //! @virtualbus SPI @dir output SPI bus
        output wire spi_sck,
        output wire [3:0] spi_sio_out,
        input wire [3:0] spi_sio_in,
        output wire [3:0] spi_sio_oe,
        //! @end

        output wire spi_flash_ss_n,
        output wire spi_psram_ss_n
    );


    localparam [2:0] CTI_INCREMENT = 3'b010;

    localparam [1:0] BTE_LINEAR = 2'b00;

    // Wishbone signals
    bit [31:0] rdt;
    bit ack;

    wire [23:0] wb_effective_adr;
    wire [3:0] wb_effective_sel;
    wire [2:0] wb_effective_cti;
    wire [1:0] wb_effective_bte;
    wire [31:0] wb_effective_dat;

    // SPI signals
    bit [3:0] sio_out;
    bit sck;
    bit sio_oe;
    bit ss_n;

    // Other
    bit [5:0] state;

    wire [7:0] read_command = 8'h0B;
    wire [7:0] write_command = 8'h38;
    wire [7:0] command = wb_we ? write_command : read_command;
    wire [7:0] mode = 8'h20;
    wire is_flash = ~wb_adr[24];
    wire is_burst = wb_effective_cti == CTI_INCREMENT & wb_effective_bte == BTE_LINEAR;
    wire at_end;

    assign wb_ack = ack && !rst && wb_cyc && wb_stb;
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;
    assign wb_rdt = rdt;

    assign spi_sck = sck;
    assign spi_sio_out = sio_out;
    assign spi_sio_oe = {sio_oe, sio_oe, sio_oe, sio_oe};
    assign spi_flash_ss_n = ss_n | ~is_flash;
    assign spi_psram_ss_n = ss_n | is_flash;

    assign at_end =
        (state[4:0] == 5'd20 & wb_we & ~wb_effective_sel[1]) |
        (state[4:0] == 5'd24 & wb_we & ~wb_effective_sel[2]) |
        (state[5] == 1'b1 & state[2:0] == 3'b000 & wb_we) |
        (state[5] == 1'b1 & state[2:0] == 3'b111 & ~is_burst);

    write_aligner #(.ADDR_WIDTH(24)) aligner(
        .wb_in_adr(wb_adr[23:0]),
        .wb_in_we(wb_we),
        .wb_in_sel(wb_sel),
        .wb_in_dat(wb_dat),
        .wb_in_cti(wb_cti),
        .wb_in_bte(wb_bte),
        .wb_out_adr(wb_effective_adr),
        .wb_out_sel(wb_effective_sel),
        .wb_out_dat(wb_effective_dat),
        .wb_out_cti(wb_effective_cti),
        .wb_out_bte(wb_effective_bte)
    );

    always_ff @ (posedge clk) begin
        if (rst || !wb_cyc || !wb_stb) begin
            state <= 6'd0;
            ack <= 1'b0;
            sio_oe <= 1'b0;
            ss_n <= 1'b1;
        end else begin
            casez (state)
                // Idle
                6'b000000: begin
                    ss_n <= 1'b0;
                    sio_oe <= 1'b1;
                    sio_out <= is_flash ? wb_effective_adr[23:20] : command[7:4];
                end

                // Command/Address phase
                6'b000010:  sio_out <= is_flash ? wb_effective_adr[19:16]   : command[3:0];
                6'b000100:  sio_out <= is_flash ? wb_effective_adr[15:12]   : wb_effective_adr[23:20];
                6'b000110:  sio_out <= is_flash ? wb_effective_adr[11:8]    : wb_effective_adr[19:16];
                6'b001000:  sio_out <= is_flash ? wb_effective_adr[7:4]     : wb_effective_adr[15:12];
                6'b?01010:  sio_out <= is_flash ? wb_effective_adr[3:0]     : wb_effective_adr[11:8];
                6'b?01100:  sio_out <= is_flash ? mode[7:4]                 : wb_effective_adr[7:4];
                6'b?01110:  sio_out <= is_flash ? mode[3:0]                 : wb_effective_adr[3:0];

                // Write / Wait phase
                6'b?10000: begin
                    sio_oe <= ~is_flash & wb_we;
                    sio_out <= wb_effective_dat[7:4];
                end
                6'b?10010: sio_out <= wb_effective_dat[3:0];
                6'b?10011: ack <= wb_we & ~wb_effective_sel[1];
                6'b?10100: begin
                    sio_out <= wb_effective_dat[15:12];
                    ss_n <= wb_we & ~wb_effective_sel[1];
                end
                6'b?10110: sio_out <= wb_effective_dat[11:8];
                6'b?10111: ack <= wb_we & ~wb_effective_sel[2];
                6'b?11000: begin
                    sio_out <= wb_effective_dat[23:20];
                    ss_n <= wb_we & ~wb_effective_sel[2];
                    if (is_burst) begin
                        ack <= 1'b0;
                    end
                end

                // Write / Read phase
                6'b?11001: begin
                    rdt[7:4] <= spi_sio_in;
                end
                6'b?11010: sio_out <= wb_effective_dat[19:16];
                6'b?11011: rdt[3:0] <= spi_sio_in;
                6'b?11100: sio_out <= wb_effective_dat[31:28];
                6'b?11101: rdt[15:12] <= spi_sio_in;
                6'b?11110: sio_out <= wb_effective_dat[27:24];
                6'b?11111: begin
                    ack <= wb_we;
                    rdt[11:8] <= spi_sio_in;
                end
                6'b100000: ss_n <= wb_we;

                // Read phase
                6'b100001: rdt[23:20] <= spi_sio_in;
                6'b100011: rdt[19:16] <= spi_sio_in;
                6'b100101: rdt[31:28] <= spi_sio_in;
                6'b100111: begin
                    ack <= 1'b1;
                    rdt[27:24] <= spi_sio_in;
                    ss_n <= ~is_burst;
                end

                6'd40: begin
                end

                default begin
                end
            endcase

            if (at_end) begin
                state <= 6'd40;
            end else if (state == 6'd39 && is_burst) begin
                state <= 6'd24; // Prepare to return next set of data
            end else if (state != 6'd40) begin
                state <= state + 6'd1;
            end

            sck <= state[0] & ~at_end;
        end
    end

    wire _unused = &{wb_effective_sel[3], wb_effective_sel[0]};
endmodule
