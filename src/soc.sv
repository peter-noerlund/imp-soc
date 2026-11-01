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

    // 3322 2222 2222 1111 1111 11
    // 1098 7654 3210 9876 5432 1098 7654 3210 
    // xxxx_xx0x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx Memory (w/arbiter)
    // xxxx_xx1x_xxxx_xxxx_xxxx_xxxx_xxx0_00xx Clock
    // xxxx_xx1x_xxxx_xxxx_xxxx_xxxx_xxx0_01xx Input
    // xxxx_xx1x_xxxx_xxxx_xxxx_xxxx_xxx0_1xxx VGA
    // xxxx_xx1x_xxxx_xxxx_xxxx_xxxx_xxx1_00xx Audio
    // xxxx_xx1x_xxxx_xxxx_xxxx_xxxx_xxx1_01xx UART
    // xxxx_xx1x_xxxx_xxxx_xxxx_xxxx_xxx1_1xxx Dummy

    // CPU wishbone bus
    wire wb_cpu_cyc;
    wire wb_cpu_stb;
    wire [31:0] wb_cpu_adr;
    wire wb_cpu_we;
    wire [3:0] wb_cpu_sel;
    wire [31:0] wb_cpu_dat;
    wire [2:0] wb_cpu_cti;
    wire [1:0] wb_cpu_bte;
    wire wb_cpu_ack;
    wire wb_cpu_err;
    wire wb_cpu_rty;
    wire [31:0] wb_cpu_rdt;

    // VGA renderer wishbone bus
    wire wb_renderer_cyc;
    wire wb_renderer_stb;
    wire [24:0] wb_renderer_adr;
    wire wb_renderer_we;
    wire [3:0] wb_renderer_sel;
    wire [31:0] wb_renderer_dat;
    wire [2:0] wb_renderer_cti;
    wire [1:0] wb_renderer_bte;
    wire wb_renderer_ack;
    wire wb_renderer_err;
    wire wb_renderer_rty;
    wire [31:0] wb_renderer_rdt;

    // CPU memory wishbone bus
    wire wb_cpu_memory_cyc;
    wire wb_cpu_memory_stb;
    wire [24:0] wb_cpu_memory_adr;
    wire wb_cpu_memory_we;
    wire [3:0] wb_cpu_memory_sel;
    wire [31:0] wb_cpu_memory_dat;
    wire [2:0] wb_cpu_memory_cti;
    wire [1:0] wb_cpu_memory_bte;
    wire wb_cpu_memory_ack;
    wire wb_cpu_memory_err;
    wire wb_cpu_memory_rty;
    wire [31:0] wb_cpu_memory_rdt;

    // Memory wishbone bus
    wire wb_memory_cyc;
    wire wb_memory_stb;
    wire [24:0] wb_memory_adr;
    wire wb_memory_we;
    wire [3:0] wb_memory_sel;
    wire [31:0] wb_memory_dat;
    wire [2:0] wb_memory_cti;
    wire [1:0] wb_memory_bte;
    wire wb_memory_ack;
    wire wb_memory_err;
    wire wb_memory_rty;
    wire [31:0] wb_memory_rdt;

    // Devices wishbone bus
    wire wb_devices_cyc;
    wire wb_devices_stb;
    wire [24:0] wb_devices_adr;
    wire wb_devices_we;
    wire [3:0] wb_devices_sel;
    wire [31:0] wb_devices_dat;
    wire [2:0] wb_devices_cti;
    wire [1:0] wb_devices_bte;
    wire wb_devices_ack;
    wire wb_devices_err;
    wire wb_devices_rty;
    wire [31:0] wb_devices_rdt;

    // Clock/Input/VGA wishbone bus
    wire wb_clock_input_vga_cyc;
    wire wb_clock_input_vga_stb;
    wire [3:0] wb_clock_input_vga_adr;
    wire wb_clock_input_vga_we;
    wire [3:0] wb_clock_input_vga_sel;
    wire [31:0] wb_clock_input_vga_dat;
    wire [2:0] wb_clock_input_vga_cti;
    wire [1:0] wb_clock_input_vga_bte;
    wire wb_clock_input_vga_ack;
    wire wb_clock_input_vga_err;
    wire wb_clock_input_vga_rty;
    wire [31:0] wb_clock_input_vga_rdt;

    // Clock/Input wishbone bus
    wire wb_clock_input_cyc;
    wire wb_clock_input_stb;
    wire [2:0] wb_clock_input_adr;
    wire wb_clock_input_we;
    wire [3:0] wb_clock_input_sel;
    wire [31:0] wb_clock_input_dat;
    wire [2:0] wb_clock_input_cti;
    wire [1:0] wb_clock_input_bte;
    wire wb_clock_input_ack;
    wire wb_clock_input_err;
    wire wb_clock_input_rty;
    wire [31:0] wb_clock_input_rdt;

    // Audio/Uart/Dummy wishbone bus
    wire wb_audio_uart_dummy_cyc;
    wire wb_audio_uart_dummy_stb;
    wire [3:0] wb_audio_uart_dummy_adr;
    wire wb_audio_uart_dummy_we;
    wire [3:0] wb_audio_uart_dummy_sel;
    wire [31:0] wb_audio_uart_dummy_dat;
    wire [2:0] wb_audio_uart_dummy_cti;
    wire [1:0] wb_audio_uart_dummy_bte;
    wire wb_audio_uart_dummy_ack;
    wire wb_audio_uart_dummy_err;
    wire wb_audio_uart_dummy_rty;
    wire [31:0] wb_audio_uart_dummy_rdt;

    // Audio/Uart/Dummy wishbone bus
    wire wb_audio_uart_cyc;
    wire wb_audio_uart_stb;
    wire [2:0] wb_audio_uart_adr;
    wire wb_audio_uart_we;
    wire [3:0] wb_audio_uart_sel;
    wire [31:0] wb_audio_uart_dat;
    wire [2:0] wb_audio_uart_cti;
    wire [1:0] wb_audio_uart_bte;
    wire wb_audio_uart_ack;
    wire wb_audio_uart_err;
    wire wb_audio_uart_rty;
    wire [31:0] wb_audio_uart_rdt;

    // Clock wishbone bus
    wire wb_clock_cyc;
    wire wb_clock_stb;
    wire [1:0] wb_clock_adr;
    wire wb_clock_we;
    wire [3:0] wb_clock_sel;
    wire [31:0] wb_clock_dat;
    wire [2:0] wb_clock_cti;
    wire [1:0] wb_clock_bte;
    wire wb_clock_ack;
    wire wb_clock_err;
    wire wb_clock_rty;
    wire [31:0] wb_clock_rdt;

    // Input wishbone bus
    wire wb_input_cyc;
    wire wb_input_stb;
    wire [1:0] wb_input_adr;
    wire wb_input_we;
    wire [3:0] wb_input_sel;
    wire [31:0] wb_input_dat;
    wire [2:0] wb_input_cti;
    wire [1:0] wb_input_bte;
    wire wb_input_ack;
    wire wb_input_err;
    wire wb_input_rty;
    wire [31:0] wb_input_rdt;

    // VGA wishbone bus
    wire wb_vga_cyc;
    wire wb_vga_stb;
    wire [2:0] wb_vga_adr;
    wire wb_vga_we;
    wire [3:0] wb_vga_sel;
    wire [31:0] wb_vga_dat;
    wire [2:0] wb_vga_cti;
    wire [1:0] wb_vga_bte;
    wire wb_vga_ack;
    wire wb_vga_err;
    wire wb_vga_rty;
    wire [31:0] wb_vga_rdt;

    // Audio wishbone bus
    wire wb_audio_cyc;
    wire wb_audio_stb;
    wire [1:0] wb_audio_adr;
    wire wb_audio_we;
    wire [3:0] wb_audio_sel;
    wire [31:0] wb_audio_dat;
    wire [2:0] wb_audio_cti;
    wire [1:0] wb_audio_bte;
    wire wb_audio_ack;
    wire wb_audio_err;
    wire wb_audio_rty;
    wire [31:0] wb_audio_rdt;

    // UART wishbone bus
    wire wb_uart_cyc;
    wire wb_uart_stb;
    wire [1:0] wb_uart_adr;
    wire wb_uart_we;
    wire [3:0] wb_uart_sel;
    wire [31:0] wb_uart_dat;
    wire [2:0] wb_uart_cti;
    wire [1:0] wb_uart_bte;
    wire wb_uart_ack;
    wire wb_uart_err;
    wire wb_uart_rty;
    wire [31:0] wb_uart_rdt;

    // Dummy wishbone bus
    wire wb_dummy_cyc;
    wire wb_dummy_stb;
    wire [2:0] wb_dummy_adr;
    wire wb_dummy_we;
    wire [3:0] wb_dummy_sel;
    wire [31:0] wb_dummy_dat;
    wire [2:0] wb_dummy_cti;
    wire [1:0] wb_dummy_bte;
    wire wb_dummy_ack;
    wire wb_dummy_err;
    wire wb_dummy_rty;
    wire [31:0] wb_dummy_rdt;

    wire vgaconfig_enabled;
    wire [3:0] vgaconfig_scale;
    wire [24:0] vgaconfig_addr;

    cpu cpu(
        .clk(clk),
        .rst(rst),

        .wb_cyc(wb_cpu_cyc),
        .wb_stb(wb_cpu_stb),
        .wb_adr(wb_cpu_adr),
        .wb_we(wb_cpu_we),
        .wb_sel(wb_cpu_sel),
        .wb_dat(wb_cpu_dat),
        .wb_cti(wb_cpu_cti),
        .wb_bte(wb_cpu_bte),
        .wb_ack(wb_cpu_ack),
        .wb_err(wb_cpu_err),
        .wb_rty(wb_cpu_rty),
        .wb_rdt(wb_cpu_rdt)
    );

    wb_interconnect #(.ADDR_WIDTH(26)) interconnect_memory_devices(
        .wb_in_cyc(wb_cpu_cyc),
        .wb_in_stb(wb_cpu_stb),
        .wb_in_adr(wb_cpu_adr[25:0]),
        .wb_in_we(wb_cpu_we),
        .wb_in_sel(wb_cpu_sel),
        .wb_in_dat(wb_cpu_dat),
        .wb_in_cti(wb_cpu_cti),
        .wb_in_bte(wb_cpu_bte),
        .wb_in_ack(wb_cpu_ack),
        .wb_in_err(wb_cpu_err),
        .wb_in_rty(wb_cpu_rty),
        .wb_in_rdt(wb_cpu_rdt),

        .wb_out0_cyc(wb_cpu_memory_cyc),
        .wb_out0_stb(wb_cpu_memory_stb),
        .wb_out0_adr(wb_cpu_memory_adr),
        .wb_out0_we(wb_cpu_memory_we),
        .wb_out0_sel(wb_cpu_memory_sel),
        .wb_out0_dat(wb_cpu_memory_dat),
        .wb_out0_cti(wb_cpu_memory_cti),
        .wb_out0_bte(wb_cpu_memory_bte),
        .wb_out0_ack(wb_cpu_memory_ack),
        .wb_out0_err(wb_cpu_memory_err),
        .wb_out0_rty(wb_cpu_memory_rty),
        .wb_out0_rdt(wb_cpu_memory_rdt),

        .wb_out1_cyc(wb_devices_cyc),
        .wb_out1_stb(wb_devices_stb),
        .wb_out1_adr(wb_devices_adr),
        .wb_out1_we(wb_devices_we),
        .wb_out1_sel(wb_devices_sel),
        .wb_out1_dat(wb_devices_dat),
        .wb_out1_cti(wb_devices_cti),
        .wb_out1_bte(wb_devices_bte),
        .wb_out1_ack(wb_devices_ack),
        .wb_out1_err(wb_devices_err),
        .wb_out1_rty(wb_devices_rty),
        .wb_out1_rdt(wb_devices_rdt)
    );

    wb_arbiter #(.ADDR_WIDTH(25)) arbiter_memory(
        .wb_in0_cyc(wb_renderer_cyc),
        .wb_in0_stb(wb_renderer_stb),
        .wb_in0_adr(wb_renderer_adr),
        .wb_in0_we(wb_renderer_we),
        .wb_in0_sel(wb_renderer_sel),
        .wb_in0_dat(wb_renderer_dat),
        .wb_in0_cti(wb_renderer_cti),
        .wb_in0_bte(wb_renderer_bte),
        .wb_in0_ack(wb_renderer_ack),
        .wb_in0_err(wb_renderer_err),
        .wb_in0_rty(wb_renderer_rty),
        .wb_in0_rdt(wb_renderer_rdt),

        .wb_in1_cyc(wb_cpu_memory_cyc),
        .wb_in1_stb(wb_cpu_memory_stb),
        .wb_in1_adr(wb_cpu_memory_adr),
        .wb_in1_we(wb_cpu_memory_we),
        .wb_in1_sel(wb_cpu_memory_sel),
        .wb_in1_dat(wb_cpu_memory_dat),
        .wb_in1_cti(wb_cpu_memory_cti),
        .wb_in1_bte(wb_cpu_memory_bte),
        .wb_in1_ack(wb_cpu_memory_ack),
        .wb_in1_err(wb_cpu_memory_err),
        .wb_in1_rty(wb_cpu_memory_rty),
        .wb_in1_rdt(wb_cpu_memory_rdt),

        .wb_out_cyc(wb_memory_cyc),
        .wb_out_stb(wb_memory_stb),
        .wb_out_adr(wb_memory_adr),
        .wb_out_we(wb_memory_we),
        .wb_out_sel(wb_memory_sel),
        .wb_out_dat(wb_memory_dat),
        .wb_out_cti(wb_memory_cti),
        .wb_out_bte(wb_memory_bte),
        .wb_out_ack(wb_memory_ack),
        .wb_out_err(wb_memory_err),
        .wb_out_rty(wb_memory_rty),
        .wb_out_rdt(wb_memory_rdt)
    );

    wb_interconnect #(.ADDR_WIDTH(5)) interconnect_clock_input_vga_audio_uart_dummy(
        .wb_in_cyc(wb_devices_cyc),
        .wb_in_stb(wb_devices_stb),
        .wb_in_adr(wb_devices_adr[4:0]),
        .wb_in_we(wb_devices_we),
        .wb_in_sel(wb_devices_sel),
        .wb_in_dat(wb_devices_dat),
        .wb_in_cti(wb_devices_cti),
        .wb_in_bte(wb_devices_bte),
        .wb_in_ack(wb_devices_ack),
        .wb_in_err(wb_devices_err),
        .wb_in_rty(wb_devices_rty),
        .wb_in_rdt(wb_devices_rdt),

        .wb_out0_cyc(wb_clock_input_vga_cyc),
        .wb_out0_stb(wb_clock_input_vga_stb),
        .wb_out0_adr(wb_clock_input_vga_adr),
        .wb_out0_we(wb_clock_input_vga_we),
        .wb_out0_sel(wb_clock_input_vga_sel),
        .wb_out0_dat(wb_clock_input_vga_dat),
        .wb_out0_cti(wb_clock_input_vga_cti),
        .wb_out0_bte(wb_clock_input_vga_bte),
        .wb_out0_ack(wb_clock_input_vga_ack),
        .wb_out0_err(wb_clock_input_vga_err),
        .wb_out0_rty(wb_clock_input_vga_rty),
        .wb_out0_rdt(wb_clock_input_vga_rdt),

        .wb_out1_cyc(wb_audio_uart_dummy_cyc),
        .wb_out1_stb(wb_audio_uart_dummy_stb),
        .wb_out1_adr(wb_audio_uart_dummy_adr),
        .wb_out1_we(wb_audio_uart_dummy_we),
        .wb_out1_sel(wb_audio_uart_dummy_sel),
        .wb_out1_dat(wb_audio_uart_dummy_dat),
        .wb_out1_cti(wb_audio_uart_dummy_cti),
        .wb_out1_bte(wb_audio_uart_dummy_bte),
        .wb_out1_ack(wb_audio_uart_dummy_ack),
        .wb_out1_err(wb_audio_uart_dummy_err),
        .wb_out1_rty(wb_audio_uart_dummy_rty),
        .wb_out1_rdt(wb_audio_uart_dummy_rdt)
    );

    wb_interconnect #(.ADDR_WIDTH(4)) interconnect_clock_input_vga(
        .wb_in_cyc(wb_clock_input_vga_cyc),
        .wb_in_stb(wb_clock_input_vga_stb),
        .wb_in_adr(wb_clock_input_vga_adr),
        .wb_in_we(wb_clock_input_vga_we),
        .wb_in_sel(wb_clock_input_vga_sel),
        .wb_in_dat(wb_clock_input_vga_dat),
        .wb_in_cti(wb_clock_input_vga_cti),
        .wb_in_bte(wb_clock_input_vga_bte),
        .wb_in_ack(wb_clock_input_vga_ack),
        .wb_in_err(wb_clock_input_vga_err),
        .wb_in_rty(wb_clock_input_vga_rty),
        .wb_in_rdt(wb_clock_input_vga_rdt),

        .wb_out0_cyc(wb_clock_input_cyc),
        .wb_out0_stb(wb_clock_input_stb),
        .wb_out0_adr(wb_clock_input_adr),
        .wb_out0_we(wb_clock_input_we),
        .wb_out0_sel(wb_clock_input_sel),
        .wb_out0_dat(wb_clock_input_dat),
        .wb_out0_cti(wb_clock_input_cti),
        .wb_out0_bte(wb_clock_input_bte),
        .wb_out0_ack(wb_clock_input_ack),
        .wb_out0_err(wb_clock_input_err),
        .wb_out0_rty(wb_clock_input_rty),
        .wb_out0_rdt(wb_clock_input_rdt),

        .wb_out1_cyc(wb_vga_cyc),
        .wb_out1_stb(wb_vga_stb),
        .wb_out1_adr(wb_vga_adr),
        .wb_out1_we(wb_vga_we),
        .wb_out1_sel(wb_vga_sel),
        .wb_out1_dat(wb_vga_dat),
        .wb_out1_cti(wb_vga_cti),
        .wb_out1_bte(wb_vga_bte),
        .wb_out1_ack(wb_vga_ack),
        .wb_out1_err(wb_vga_err),
        .wb_out1_rty(wb_vga_rty),
        .wb_out1_rdt(wb_vga_rdt)
    );

    wb_interconnect #(.ADDR_WIDTH(4)) interconnect_audio_uart_dummy(
        .wb_in_cyc(wb_audio_uart_dummy_cyc),
        .wb_in_stb(wb_audio_uart_dummy_stb),
        .wb_in_adr(wb_audio_uart_dummy_adr),
        .wb_in_we(wb_audio_uart_dummy_we),
        .wb_in_sel(wb_audio_uart_dummy_sel),
        .wb_in_dat(wb_audio_uart_dummy_dat),
        .wb_in_cti(wb_audio_uart_dummy_cti),
        .wb_in_bte(wb_audio_uart_dummy_bte),
        .wb_in_ack(wb_audio_uart_dummy_ack),
        .wb_in_err(wb_audio_uart_dummy_err),
        .wb_in_rty(wb_audio_uart_dummy_rty),
        .wb_in_rdt(wb_audio_uart_dummy_rdt),

        .wb_out0_cyc(wb_audio_uart_cyc),
        .wb_out0_stb(wb_audio_uart_stb),
        .wb_out0_adr(wb_audio_uart_adr),
        .wb_out0_we(wb_audio_uart_we),
        .wb_out0_sel(wb_audio_uart_sel),
        .wb_out0_dat(wb_audio_uart_dat),
        .wb_out0_cti(wb_audio_uart_cti),
        .wb_out0_bte(wb_audio_uart_bte),
        .wb_out0_ack(wb_audio_uart_ack),
        .wb_out0_err(wb_audio_uart_err),
        .wb_out0_rty(wb_audio_uart_rty),
        .wb_out0_rdt(wb_audio_uart_rdt),

        .wb_out1_cyc(wb_dummy_cyc),
        .wb_out1_stb(wb_dummy_stb),
        .wb_out1_adr(wb_dummy_adr),
        .wb_out1_we(wb_dummy_we),
        .wb_out1_sel(wb_dummy_sel),
        .wb_out1_dat(wb_dummy_dat),
        .wb_out1_cti(wb_dummy_cti),
        .wb_out1_bte(wb_dummy_bte),
        .wb_out1_ack(wb_dummy_ack),
        .wb_out1_err(wb_dummy_err),
        .wb_out1_rty(wb_dummy_rty),
        .wb_out1_rdt(wb_dummy_rdt)
    );

    wb_interconnect #(.ADDR_WIDTH(3)) interconnect_clock_input(
        .wb_in_cyc(wb_clock_input_cyc),
        .wb_in_stb(wb_clock_input_stb),
        .wb_in_adr(wb_clock_input_adr),
        .wb_in_we(wb_clock_input_we),
        .wb_in_sel(wb_clock_input_sel),
        .wb_in_dat(wb_clock_input_dat),
        .wb_in_cti(wb_clock_input_cti),
        .wb_in_bte(wb_clock_input_bte),
        .wb_in_ack(wb_clock_input_ack),
        .wb_in_err(wb_clock_input_err),
        .wb_in_rty(wb_clock_input_rty),
        .wb_in_rdt(wb_clock_input_rdt),

        .wb_out0_cyc(wb_clock_cyc),
        .wb_out0_stb(wb_clock_stb),
        .wb_out0_adr(wb_clock_adr),
        .wb_out0_we(wb_clock_we),
        .wb_out0_sel(wb_clock_sel),
        .wb_out0_dat(wb_clock_dat),
        .wb_out0_cti(wb_clock_cti),
        .wb_out0_bte(wb_clock_bte),
        .wb_out0_ack(wb_clock_ack),
        .wb_out0_err(wb_clock_err),
        .wb_out0_rty(wb_clock_rty),
        .wb_out0_rdt(wb_clock_rdt),

        .wb_out1_cyc(wb_input_cyc),
        .wb_out1_stb(wb_input_stb),
        .wb_out1_adr(wb_input_adr),
        .wb_out1_we(wb_input_we),
        .wb_out1_sel(wb_input_sel),
        .wb_out1_dat(wb_input_dat),
        .wb_out1_cti(wb_input_cti),
        .wb_out1_bte(wb_input_bte),
        .wb_out1_ack(wb_input_ack),
        .wb_out1_err(wb_input_err),
        .wb_out1_rty(wb_input_rty),
        .wb_out1_rdt(wb_input_rdt)
    );

    clock_device #(.ADDR_WIDTH(2)) clock_device(
        .clk(clk),
        .rst(rst),
        .wb_cyc(wb_clock_cyc),
        .wb_stb(wb_clock_stb),
        .wb_adr(wb_clock_adr),
        .wb_we(wb_clock_we),
        .wb_sel(wb_clock_sel),
        .wb_dat(wb_clock_dat),
        .wb_cti(wb_clock_cti),
        .wb_bte(wb_clock_bte),
        .wb_ack(wb_clock_ack),
        .wb_err(wb_clock_err),
        .wb_rty(wb_clock_rty),
        .wb_rdt(wb_clock_rdt)
    );

    dummy_device #(.ADDR_WIDTH(2)) input_device(
        .clk(clk),
        .rst(rst),
        .wb_cyc(wb_input_cyc),
        .wb_stb(wb_input_stb),
        .wb_adr(wb_input_adr),
        .wb_we(wb_input_we),
        .wb_sel(wb_input_sel),
        .wb_dat(wb_input_dat),
        .wb_cti(wb_input_cti),
        .wb_bte(wb_input_bte),
        .wb_ack(wb_input_ack),
        .wb_err(wb_input_err),
        .wb_rty(wb_input_rty),
        .wb_rdt(wb_input_rdt)
    );

    dummy_device #(.ADDR_WIDTH(2)) audio_device(
        .clk(clk),
        .rst(rst),
        .wb_cyc(wb_audio_cyc),
        .wb_stb(wb_audio_stb),
        .wb_adr(wb_audio_adr),
        .wb_we(wb_audio_we),
        .wb_sel(wb_audio_sel),
        .wb_dat(wb_audio_dat),
        .wb_cti(wb_audio_cti),
        .wb_bte(wb_audio_bte),
        .wb_ack(wb_audio_ack),
        .wb_err(wb_audio_err),
        .wb_rty(wb_audio_rty),
        .wb_rdt(wb_audio_rdt)
    );

    memory_device memory_device(
        .clk(clk),
        .rst(rst),
        .wb_cyc(wb_memory_cyc),
        .wb_stb(wb_memory_stb),
        .wb_adr(wb_memory_adr),
        .wb_we(wb_memory_we),
        .wb_sel(wb_memory_sel),
        .wb_dat(wb_memory_dat),
        .wb_cti(wb_memory_cti),
        .wb_bte(wb_memory_bte),
        .wb_ack(wb_memory_ack),
        .wb_err(wb_memory_err),
        .wb_rty(wb_memory_rty),
        .wb_rdt(wb_memory_rdt),
        .spi_sck(spi_sck),
        .spi_sio_out(spi_sio_out),
        .spi_sio_oe(spi_sio_oe),
        .spi_sio_in(spi_sio_in),
        .spi_flash_ss_n(spi_flash_ss_n),
        .spi_psram_ss_n(spi_psram_ss_n)
    );

    vga_device #(.ADDR_WIDTH(25)) vga_device(
        .clk(clk),
        .rst(rst),

        .wb_cyc(wb_vga_cyc),
        .wb_stb(wb_vga_stb),
        .wb_adr(25'(wb_vga_adr)),
        .wb_we(wb_vga_we),
        .wb_sel(wb_vga_sel),
        .wb_dat(wb_vga_dat),
        .wb_cti(wb_vga_cti),
        .wb_bte(wb_vga_bte),
        .wb_ack(wb_vga_ack),
        .wb_err(wb_vga_err),
        .wb_rty(wb_vga_rty),
        .wb_rdt(wb_vga_rdt),

        .vgaconfig_enabled(vgaconfig_enabled),
        .vgaconfig_addr(vgaconfig_addr),
        .vgaconfig_scale(vgaconfig_scale)
    );

    vga_renderer #(.ADDR_WIDTH(25)) vga_renderer(
        .clk(clk),
        .rst(rst),

        .wb_cyc(wb_renderer_cyc),
        .wb_stb(wb_renderer_stb),
        .wb_adr(wb_renderer_adr),
        .wb_we(wb_renderer_we),
        .wb_sel(wb_renderer_sel),
        .wb_dat(wb_renderer_dat),
        .wb_cti(wb_renderer_cti),
        .wb_bte(wb_renderer_bte),
        .wb_ack(wb_renderer_ack),
        .wb_err(wb_renderer_err),
        .wb_rty(wb_renderer_rty),
        .wb_rdt(wb_renderer_rdt),

        .vgaconfig_enabled(vgaconfig_enabled),
        .vgaconfig_addr(vgaconfig_addr),
        .vgaconfig_scale(vgaconfig_scale),

        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue)
    );

    generate
        if (ENABLE_UART) begin
            uart_device #(.ADDR_WIDTH(2)) uart_device(
                .clk(clk),
                .rst(rst),
                .wb_cyc(wb_uart_cyc),
                .wb_stb(wb_uart_stb),
                .wb_adr(wb_uart_adr),
                .wb_we(wb_uart_we),
                .wb_sel(wb_uart_sel),
                .wb_dat(wb_uart_dat),
                .wb_cti(wb_uart_cti),
                .wb_bte(wb_uart_bte),
                .wb_ack(wb_uart_ack),
                .wb_err(wb_uart_err),
                .wb_rty(wb_uart_rty),
                .wb_rdt(wb_uart_rdt),
                .uart_tx(uart_tx)
            );
        end else begin
            dummy_device #(.ADDR_WIDTH(2)) uart_device(
                .clk(clk),
                .rst(rst),
                .wb_cyc(wb_uart_cyc),
                .wb_stb(wb_uart_stb),
                .wb_adr(wb_uart_adr),
                .wb_we(wb_uart_we),
                .wb_sel(wb_uart_sel),
                .wb_dat(wb_uart_dat),
                .wb_cti(wb_uart_cti),
                .wb_bte(wb_uart_bte),
                .wb_ack(wb_uart_ack),
                .wb_err(wb_uart_err),
                .wb_rty(wb_uart_rty),
                .wb_rdt(wb_uart_rdt)
            );

            assign uart_tx = 1'b1;
        end
    endgenerate
endmodule
