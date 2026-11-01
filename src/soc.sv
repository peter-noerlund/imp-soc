`default_nettype none

module soc
    #(
        parameter [0:0] ENABLE_UART=0
    )
    (
        input wire clk,
        input wire rst,

        output wire uart_tx,

        output wire spi_sck,
        output wire [3:0] spi_sio_out,
        output wire [3:0] spi_sio_oe,
        input wire [3:0] spi_sio_in,
        output wire spi_flash_ss_n,
        output wire spi_psram_ss_n,

        output wire vga_hsync,
        output wire vga_vsync,
        output wire [1:0] vga_red,
        output wire [1:0] vga_green,
        output wire [1:0] vga_blue
    );

    // Main wishbone bus
    wire wb_cyc;
    wire wb_stb;
    wire [26:0] wb_adr;
    wire wb_we;
    wire [3:0] wb_sel;
    wire [31:0] wb_dat;
    wire [2:0] wb_cti;
    wire [1:0] wb_bte;
    wire wb_ack;
    wire wb_rty;
    wire wb_err;
    wire [31:0] wb_rdt;


    // Memory
    wire wb_mem_stb;
    wire wb_mem_ack;
    wire wb_mem_err;
    wire wb_mem_rty;
    wire [31:0] wb_mem_rdt;

    // Clock
    wire wb_clock_stb;
    wire wb_clock_ack;
    wire wb_clock_err;
    wire wb_clock_rty;
    wire [31:0] wb_clock_rdt;

    // UART
    wire wb_uart_stb;
    wire wb_uart_ack;
    wire wb_uart_err;
    wire wb_uart_rty;
    wire [31:0] wb_uart_rdt;

    assign vga_hsync = 1'b1;
    assign vga_vsync = 1'b1;
    assign vga_red = 2'b00;
    assign vga_green = 2'b00;
    assign vga_blue = 2'b00;

    cpu cpu(
        .clk(clk),
        .rst(rst),

        .wb_cyc(wb_cyc),
        .wb_stb(wb_stb),
        .wb_adr(wb_adr),
        .wb_we(wb_we),
        .wb_sel(wb_sel),
        .wb_dat(wb_dat),
        .wb_cti(wb_cti),
        .wb_bte(wb_bte),
        .wb_ack(wb_ack),
        .wb_rty(wb_rty),
        .wb_err(wb_err),
        .wb_rdt(wb_rdt)
    );

    wb_interconnect #(.ADDR_WIDTH(27)) interconnect(
        .wb_in_stb(wb_stb),
        .wb_in_adr(wb_adr),
        .wb_in_ack(wb_ack),
        .wb_in_rty(wb_rty),
        .wb_in_err(wb_err),
        .wb_in_rdt(wb_rdt),

        .wb_mem_stb(wb_mem_stb),
        .wb_mem_ack(wb_mem_ack),
        .wb_mem_rty(wb_mem_rty),
        .wb_mem_err(wb_mem_err),
        .wb_mem_rdt(wb_mem_rdt),

        .wb_clock_stb(wb_clock_stb),
        .wb_clock_ack(wb_clock_ack),
        .wb_clock_rty(wb_clock_rty),
        .wb_clock_err(wb_clock_err),
        .wb_clock_rdt(wb_clock_rdt),

        .wb_uart_stb(wb_uart_stb),
        .wb_uart_ack(wb_uart_ack),
        .wb_uart_rty(wb_uart_rty),
        .wb_uart_err(wb_uart_err),
        .wb_uart_rdt(wb_uart_rdt)
    );

    memory_device memory_device(
        .clk(clk),
        .rst(rst),

        .wb_cyc(wb_cyc),
        .wb_stb(wb_mem_stb),
        .wb_adr(wb_adr[24:0]),
        .wb_we(wb_we),
        .wb_sel(wb_sel),
        .wb_dat(wb_dat),
        .wb_cti(wb_cti),
        .wb_bte(wb_bte),
        .wb_ack(wb_mem_ack),
        .wb_rty(wb_mem_rty),
        .wb_err(wb_mem_err),
        .wb_rdt(wb_mem_rdt),

        .spi_sck(spi_sck),
        .spi_sio_out(spi_sio_out),
        .spi_sio_in(spi_sio_in),
        .spi_sio_oe(spi_sio_oe),
        .spi_flash_ss_n(spi_flash_ss_n),
        .spi_psram_ss_n(spi_psram_ss_n)
    );

    clock_device #(.ADDR_WIDTH(2)) clock_device(
        .clk(clk),
        .rst(rst),

        .wb_cyc(wb_cyc),
        .wb_stb(wb_clock_stb),
        .wb_adr(wb_adr[1:0]),
        .wb_we(wb_we),
        .wb_sel(wb_sel),
        .wb_dat(wb_dat),
        .wb_cti(wb_cti),
        .wb_bte(wb_bte),
        .wb_ack(wb_clock_ack),
        .wb_rty(wb_clock_rty),
        .wb_err(wb_clock_err),
        .wb_rdt(wb_clock_rdt)
    );

    uart_device #(.ADDR_WIDTH(2)) uart_device(
        .clk(clk),
        .rst(rst),

        .wb_cyc(wb_cyc),
        .wb_stb(wb_uart_stb),
        .wb_adr(wb_adr[1:0]),
        .wb_we(wb_we),
        .wb_sel(wb_sel),
        .wb_dat(wb_dat),
        .wb_cti(wb_cti),
        .wb_bte(wb_bte),
        .wb_ack(wb_uart_ack),
        .wb_rty(wb_uart_rty),
        .wb_err(wb_uart_err),
        .wb_rdt(wb_uart_rdt)
    );
endmodule
