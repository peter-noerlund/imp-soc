`default_nettype none

module init_qspi_pmod_top
    (
        input wire clk25,

        output wire LED,
        inout wire [7:0] P3_PMOD2
    );

    // flash_cs psram_cs quad_oe oe sio[3:0]

    wire clk;
    wire clk_locked;
    wire rst;

    wire spi_sck;
    wire spi_flash_ss_n;
    wire spi_psram_ss_n;
    wire [3:0] spi_sio_out;
    wire [3:0] spi_sio_oe;

    wire done;

    wire [7:0] p3_pmod2_in;
    wire [7:0] p3_pmod2_oe;
    wire [7:0] p3_pmod2_out;

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

    init_qspi_pmod init_qspi_pmod(
        .clk(clk),
        .rst(rst),
        .spi_sck(spi_sck),
        .spi_flash_ss_n(spi_flash_ss_n),
        .spi_psram_ss_n(spi_psram_ss_n),
        .spi_sio_oe(spi_sio_oe),
        .spi_sio_out(spi_sio_out),
        .done(done)
    );
endmodule
