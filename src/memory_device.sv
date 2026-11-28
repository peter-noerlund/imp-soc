`default_nettype none

/**
 * QSPI memory controller
 *
 * Exposes a QSPI-driven flash and PSRAM via a Wishbone bus.
 *
 * The first 16MB goes to the flash which is expected to be put in to continous fast quad read.
 * The next 8MB goes to the first PSRAM which is expected to be set in QPI mode.
 *
 * The expected frequency is 65MHz, so a clock cycle is 15.38 ns and tCH / tCL is 7.69 ns
 * The PSRAM takes 2 - 5.5ns (tACLK) for data to be valid after SCK falling edge
 * The Flash can take up to 1.5 - 6 ns (tCLQV / tCLQX) for data to be valid after SCK falling edge
 * The Tiny Tapeout mutiplexer has a rising edge latency at about 20.4 ± 2 ns and the falling edge delay at about 16.3 ± 2 ns.
 *
 * So from the internal clock edge, it takes 15.8 - 28.4 ns for data to be valid, so we have to wait an additional cycle for data.
 */
module memory_device
    #(
        parameter [1:0] DEFAULT_DELAY=2'd1  // Number of additional clock cycles to wait before reading from SPI
    )
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

    localparam [3:0] STATE_IDLE = 4'd0;
    localparam [3:0] STATE_COMMAND = 4'd1;
    localparam [3:0] STATE_ADDR0 = 4'd2;
    localparam [3:0] STATE_ADDR1 = 4'd3;
    localparam [3:0] STATE_ADDR2 = 4'd4;
    localparam [3:0] STATE_MODE = 4'd5;
    localparam [3:0] STATE_DUMMY0 = 4'd6;
    localparam [3:0] STATE_DUMMY1 = 4'd7;
    localparam [3:0] STATE_DATA0 = 4'd8;
    localparam [3:0] STATE_DATA1 = 4'd9;
    localparam [3:0] STATE_DATA2 = 4'd10;
    localparam [3:0] STATE_DATA3 = 4'd11;
    localparam [3:0] STATE_IVALID = 4'bxxxx;

    bit [2:0] next_state;
    bit [2:0] state;
    bit [1:0] cnt;
    bit ss_n;
    bit [3:0] dout;
    bit oe;
    wire [7:0] next_output_byte;
    wire is_flash = ~wb_adr[24];
    wire is_last = &{cnt};
    wire is_mid = cnt[0] & ~cnt[1];
    wire is_burst = wb_cti == CT_INCREMENT;

    assign spi_sck = cnt[0];
    assign spi_flash_ss_n = ss_n | ~is_flash;
    assign spi_psram_ss_n = ss_n | is_flash;
    assign spi_sio_oe = {oe, oe, oe, oe};
    assign spi_sio_out = dout;

    always_comb begin
        next_state = state;

        if (is_last) begin
            case (state)
                STATE_IDLE:     next_state = (wb_cyc & wb_stb) ? (is_flash ? STATE_ADDR0 : STATE_CMD) : STATE_IDLE;
                STATE_CMD:      next_state = STATE_ADDR0;
                STATE_ADDR0:    next_state = STATE_ADDR1;
                STATE_ADDR1:    next_state = STATE_ADDR2;
                STATE_ADDR2:    next_state = is_flash ? STATE_MODE : STATE_DUMMY0;;
                STATE_MODE:     next_state = STATE_DUMMY0;
                STATE_DUMMY0:   next_state = STATE_DUMMY1;
                STATE_DUMMY1:   next_state = STATE_DATA0;
                STATE_DATA0:    next_state = STATE_DATA1;
                STATE_DATA1:    next_state = STATE_DATA2;
                STATE_DATA2:    next_state = STATE_DATA3;
                STATE_DATA3:    next_state = is_burst ? STATE_DATA0 : STATE_IDLE;
                default:        next_state = STATE_INVALID;
            endcase
        end
    end

    always_comb begin
        case (next_state)
            STATE_CMD:      next_output_byte = wb_we ? 8'h0B : 8'h38;
            STATE_ADDR0:    next_output_byte = wb_adr[23:16];
            STATE_ADDR1:    next_output_byte = wb_adr[15:8];
            STATE_ADDR2:    next_output_byte = wb_adr[7:0];
            STATE_MODE:     next_output_byte = 8'h20;
            STATE_DATA0:    next_output_byte = wb_dat[7:0];
            STATE_DATA1:    next_output_byte = wb_adr[15:8];
            STATE_DATA2:    next_output_byte = wb_adr[23:16];
            STATE_DATA3:    next_output_byte = wb_adr[31:24];
            default:        next_output_byte = 8'hxx;
        end
    end

    always_ff @ (posedge clk) begin
        dout <= cnt[0] ^ cnt[1] ? next_output_byte[3:0] : next_output_byte[7:4];
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            oe <= 1'b0;
        end begin
            if (next_state == STATE_CMD || next_state == STATE_ADDR0) begin
                oe <= 1'b1;
            end else if (next_state == STATE_DUMMY0) begin
                oe <= 1'b0;
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            cnt <= 2'd0;
        end else begin
            cnt <= cnt + 2'd1;
        end
    end

    wire _unused = &{wb_effective_sel[3], wb_effective_sel[0]};
endmodule
