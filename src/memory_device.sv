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
    localparam [2:0] CTI_END_OF_BURST = 3'b111;

    localparam [1:0] BTE_LINEAR = 2'b00;

    // Wishbone signals
    bit [31:0] rdt;
    bit ack;

    wire [23:0] wb_effective_adr;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [3:0] wb_effective_sel;
    wire [2:0] wb_effective_cti;
    wire [1:0] wb_effective_bte;
    /* verilator lint_on UNUSEDSIGNAL */
    wire [31:0] wb_effective_dat;

    // SPI signals
    bit sck;
    bit [3:0] sio_out;
    bit sio_oe_write_quad;
    bit sio_oe_write;
    bit ss_n;

    // Other
    bit [4:0] state;

    wire [7:0] command;
    wire [7:0] read_command;
    wire [7:0] write_command;

    assign wb_ack = ack && !rst && wb_cyc && wb_stb;
    assign wb_rty = 1'b0;
    assign wb_err = 1'b0;
    assign wb_rdt = rdt;

    assign spi_sck = sck;
    assign spi_sio_out = sio_out;
    assign spi_sio_oe = {sio_oe_write_quad, sio_oe_write_quad, sio_oe_write_quad, sio_oe_write};
    assign spi_flash_ss_n = ss_n | wb_adr[24];
    assign spi_psram_ss_n = ss_n | ~wb_adr[24];

    assign read_command = 8'hEB;
    assign write_command = 8'h38;
    assign command = wb_we ? write_command : read_command;

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
            state <= 5'd0;

            ack <= 1'b0;

            sck <= 1'b0;
            sio_oe_write <= 1'b0;
            sio_oe_write_quad <= 1'b0;
            ss_n <= 1'b1;
        end else begin
            if (!ss_n) begin
                // FIXME: Currently, we are setting the clock high at the last nibble,
                // which actually causes the device to continue to next byte just before termination
                sck <= ~sck;
            end

            case (state)
                5'd0: begin
                    ss_n <= 1'b0;
                    sio_oe_write <= 1'b1;
                    sio_out[0] <= command[7];
                end

                5'd2: if (sck) begin
                    sio_out[0] <= command[6];
                end

                5'd3: if (sck) begin
                    sio_out[0] <= command[5];
                end

                5'd4: if (sck) begin
                    sio_out[0] <= command[4];
                end

                5'd5: if (sck) begin
                    sio_out[0] <= command[3];
                end

                5'd6: if (sck) begin
                    sio_out[0] <= command[2];
                end

                5'd7: if (sck) begin
                    sio_out[0] <= command[1];
                end

                5'd8: if (sck) begin
                    sio_out[0] <= command[0];
                end

                5'd9: if (sck) begin
                    sio_oe_write_quad <= 1'b1;
                    sio_out <= wb_effective_adr[23:20];
                end

                5'd10: if (sck) begin
                    sio_out <= wb_effective_adr[19:16];
                end

                5'd11: if (sck) begin
                    sio_out <= wb_effective_adr[15:12];
                end

                5'd12: if (sck) begin
                    sio_out <= wb_effective_adr[11:8];
                end

                5'd13: if (sck) begin
                    sio_out <= wb_effective_adr[7:4];
                end

                5'd14: if (sck) begin
                    sio_out <= wb_effective_adr[3:0];
                end

                5'd15: if (sck) begin
                    // Write nibble / Wait cycle 1
                    sio_out <= wb_effective_dat[7:4];
                    sio_oe_write <= wb_we;
                    sio_oe_write_quad <= wb_we;
                end

                5'd16: if (sck) begin
                    // Write nibble / Wait cycle 2
                    sio_out <= wb_effective_dat[3:0];
                end

                5'd17: if (sck) begin
                    // Write nibble / Wait cycle 3
                    sio_out <= wb_effective_dat[15:12];
                    // Stop if 1 byte write
                    if (wb_we && wb_effective_sel[1] == 1'b0) begin
                        ack <= 1'b1;
                        ss_n <= 1'b1;
                        sio_oe_write <= 1'b0;
                        sio_oe_write_quad <= 1'b0;
                    end
                end

                5'd18: if (sck) begin
                    // Write nibble / Wait cycle 4
                    sio_out <= wb_effective_dat[11:8];
                end

                5'd19: if (sck) begin
                    // Write nibble / Wait cycle 5
                    sio_out <= wb_effective_dat[23:20];
                    // Stop if 2 byte write
                    if (wb_we && wb_effective_sel[2] == 1'b0) begin
                        ack <= 1'b1;
                        ss_n <= 1'b1;
                        sio_oe_write <= 1'b0;
                        sio_oe_write_quad <= 1'b0;
                    end
                end

                5'd20: if (sck) begin
                    // Write nibble / Wait cycle 6
                    sio_out <= wb_effective_dat[19:16];
                end

                5'd21: if (sck) begin
                    sio_out <= wb_effective_dat[31:28];
                end

                5'd22: if (sck) begin
                    rdt[7:4] <= spi_sio_in;
                    sio_out <= wb_effective_dat[27:24];
                end

                5'd23: if (sck) begin
                    rdt[3:0] <= spi_sio_in;
                    if (wb_we) begin
                        // Stop if write                    
                        ack <= 1'b1;
                        ss_n <= 1'b1;
                        sio_oe_write <= 1'b0;
                        sio_oe_write_quad <= 1'b0;
                    end
                end

                5'd24: if (sck) begin
                    rdt[15:12] <= spi_sio_in;
                end

                5'd25: if (sck) begin
                    rdt[11:8] <= spi_sio_in;
                end

                5'd26: if (sck) begin
                    rdt[23:20] <= spi_sio_in;
                end

                5'd27: if (sck) begin
                    rdt[19:16] <= spi_sio_in;
                end

                5'd28: if (sck) begin
                    rdt[31:28] <= spi_sio_in;
                end

                5'd29: if (sck) begin
                    rdt[27:24] <= spi_sio_in;
                    // Stop
                    ack <= 1'b1;
                    if (wb_cti != CTI_INCREMENT || wb_bte != BTE_LINEAR) begin
                        ss_n <= 1'b1;
                    end
                end

                default: begin
                    
                end
            endcase

            if (!sck) begin
                if (state == 5'd29 && wb_cti == CTI_INCREMENT && wb_bte == BTE_LINEAR) begin
                    state <= 5'd22;
                end else begin
                    state <= state + 5'd1;
                end
            end

            if (ack) begin
                ack <= 1'b0;
            end
        end
    end

    /*
        Signals

        bit_counter |
        0 (ss_n)    | Send command bit 7
        0           | Send command bit 6
        1           | Send command bit 5
        2           | Send command bit 4
        3           | Send command bit 3
        4           | Send command bit 2
        5           | Send command bit 1
        6           | Send command bit 0
        7           | Send address bit 23-20
        8           | Send address bit 19-16
        9           | Send address bit 15-12
        10          | Send address bit 11-8
        11          | Send address bit 7-4
        12          | Send address bit 3-0
        13          | Send byte 0 bit 7:4       | Toggle input pins
        14          | Send byte 0 bit 3:0       |
        15          | Send byte 1 bit 7:4       |
        16          | Send byte 1 bit 3:0       |
        17          | Send byte 2 bit 7:4       |
        18          | Send byte 2 bit 3:0       |
        19          | Send byte 3 bit 7:4       | Receive byte 0 bit 7:4
        20          | Send byte 3 bit 3:0       | Receive byte 0 bit 3:0
        21          |                           | Receive byte 1 bit 7:4
        22          |                           | Receive byte 1 bit 3:0
        23          |                           | Receive byte 2 bit 7:4
        24          |                           | Receive byte 2 bit 3:0
        25          |                           | Receive byte 3 bit 7:4
        26          |                           | Receive byte 3 bit 3:0
    */
endmodule
