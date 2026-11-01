`default_nettype none

module soc
    #(
        parameter [0:0] ENABLE_UART=0,
        parameter [0:0] ENABLE_VIDEO=1
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

    // Video renderer wishbone bus
    wire wb_renderer_cyc;
    wire wb_renderer_stb;
    wire [25:0] wb_renderer_adr;
    wire wb_renderer_we;
    wire [3:0] wb_renderer_sel;
    wire [31:0] wb_renderer_dat;
    wire [2:0] wb_renderer_cti;
    wire [1:0] wb_renderer_bte;
    wire wb_renderer_ack;
    wire wb_renderer_err;
    wire wb_renderer_rty;
    wire [31:0] wb_renderer_rdt;

    // Main wishbone bus
    wire wb_main_cyc;
    wire wb_main_stb;
    wire [25:0] wb_main_adr;
    wire wb_main_we;
    wire [3:0] wb_main_sel;
    wire [31:0] wb_main_dat;
    wire [2:0] wb_main_cti;
    wire [1:0] wb_main_bte;
    wire wb_main_ack;
    wire wb_main_err;
    wire wb_main_rty;
    wire [31:0] wb_main_rdt;

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

    // Null/Clock/Video/Ctrl wishbone bus (4-bit address)
    wire wb_null_clock_video_ctrl_cyc;
    wire wb_null_clock_video_ctrl_stb;
    wire [3:0] wb_null_clock_video_ctrl_adr;
    wire wb_null_clock_video_ctrl_we;
    wire [3:0] wb_null_clock_video_ctrl_sel;
    wire [31:0] wb_null_clock_video_ctrl_dat;
    wire [2:0] wb_null_clock_video_ctrl_cti;
    wire [1:0] wb_null_clock_video_ctrl_bte;
    wire wb_null_clock_video_ctrl_ack;
    wire wb_null_clock_video_ctrl_err;
    wire wb_null_clock_video_ctrl_rty;
    wire [31:0] wb_null_clock_video_ctrl_rdt;

    // Multiply/UART/Audio wishbone bus (4-bit address)
    wire wb_mul_uart_audio_cyc;
    wire wb_mul_uart_audio_stb;
    wire [3:0] wb_mul_uart_audio_adr;
    wire wb_mul_uart_audio_we;
    wire [3:0] wb_mul_uart_audio_sel;
    wire [31:0] wb_mul_uart_audio_dat;
    wire [2:0] wb_mul_uart_audio_cti;
    wire [1:0] wb_mul_uart_audio_bte;
    wire wb_mul_uart_audio_ack;
    wire wb_mul_uart_audio_err;
    wire wb_mul_uart_audio_rty;
    wire [31:0] wb_mul_uart_audio_rdt;

    // Null/Clock wishbone bus (3-bit address)
    wire wb_null_clock_cyc;
    wire wb_null_clock_stb;
    wire [2:0] wb_null_clock_adr;
    wire wb_null_clock_we;
    wire [3:0] wb_null_clock_sel;
    wire [31:0] wb_null_clock_dat;
    wire [2:0] wb_null_clock_cti;
    wire [1:0] wb_null_clock_bte;
    wire wb_null_clock_ack;
    wire wb_null_clock_err;
    wire wb_null_clock_rty;
    wire [31:0] wb_null_clock_rdt;

    // Video/Controller wishbone bus (3-bit address)
    wire wb_video_ctrl_cyc;
    wire wb_video_ctrl_stb;
    wire [2:0] wb_video_ctrl_adr;
    wire wb_video_ctrl_we;
    wire [3:0] wb_video_ctrl_sel;
    wire [31:0] wb_video_ctrl_dat;
    wire [2:0] wb_video_ctrl_cti;
    wire [1:0] wb_video_ctrl_bte;
    wire wb_video_ctrl_ack;
    wire wb_video_ctrl_err;
    wire wb_video_ctrl_rty;
    wire [31:0] wb_video_ctrl_rdt;

    // Uart/Audio wishbone bus (3-bit address)
    wire wb_uart_audio_cyc;
    wire wb_uart_audio_stb;
    wire [2:0] wb_uart_audio_adr;
    wire wb_uart_audio_we;
    wire [3:0] wb_uart_audio_sel;
    wire [31:0] wb_uart_audio_dat;
    wire [2:0] wb_uart_audio_cti;
    wire [1:0] wb_uart_audio_bte;
    wire wb_uart_audio_ack;
    wire wb_uart_audio_err;
    wire wb_uart_audio_rty;
    wire [31:0] wb_uart_audio_rdt;

    // Null wishbone bus
    wire wb_null_cyc;
    wire wb_null_stb;
    wire [1:0] wb_null_adr;
    wire wb_null_we;
    wire [3:0] wb_null_sel;
    wire [31:0] wb_null_dat;
    wire [2:0] wb_null_cti;
    wire [1:0] wb_null_bte;
    wire wb_null_ack;
    wire wb_null_err;
    wire wb_null_rty;
    wire [31:0] wb_null_rdt;

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

    // Video wishbone bus
    wire wb_video_cyc;
    wire wb_video_stb;
    wire [1:0] wb_video_adr;
    wire wb_video_we;
    wire [3:0] wb_video_sel;
    wire [31:0] wb_video_dat;
    wire [2:0] wb_video_cti;
    wire [1:0] wb_video_bte;
    wire wb_video_ack;
    wire wb_video_err;
    wire wb_video_rty;
    wire [31:0] wb_video_rdt;

    // Controller wishbone bus
    wire wb_ctrl_cyc;
    wire wb_ctrl_stb;
    wire [1:0] wb_ctrl_adr;
    wire wb_ctrl_we;
    wire [3:0] wb_ctrl_sel;
    wire [31:0] wb_ctrl_dat;
    wire [2:0] wb_ctrl_cti;
    wire [1:0] wb_ctrl_bte;
    wire wb_ctrl_ack;
    wire wb_ctrl_err;
    wire wb_ctrl_rty;
    wire [31:0] wb_ctrl_rdt;

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

    // Multiply wishbone bus
    wire wb_mul_cyc;
    wire wb_mul_stb;
    wire [2:0] wb_mul_adr;
    wire wb_mul_we;
    wire [3:0] wb_mul_sel;
    wire [31:0] wb_mul_dat;
    wire [2:0] wb_mul_cti;
    wire [1:0] wb_mul_bte;
    wire wb_mul_ack;
    wire wb_mul_err;
    wire wb_mul_rty;
    wire [31:0] wb_mul_rdt;

    wire fb_enabled;
    wire [25:0] fb_addr;

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
    
    generate
        if (ENABLE_VIDEO) begin
            wb_arbiter #(.ADDR_WIDTH(26)) arbiter(
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

                .wb_in1_cyc(wb_cpu_cyc),
                .wb_in1_stb(wb_cpu_stb),
                .wb_in1_adr(wb_cpu_adr[25:0]),
                .wb_in1_we(wb_cpu_we),
                .wb_in1_sel(wb_cpu_sel),
                .wb_in1_dat(wb_cpu_dat),
                .wb_in1_cti(wb_cpu_cti),
                .wb_in1_bte(wb_cpu_bte),
                .wb_in1_ack(wb_cpu_ack),
                .wb_in1_err(wb_cpu_err),
                .wb_in1_rty(wb_cpu_rty),
                .wb_in1_rdt(wb_cpu_rdt),

                .wb_out_cyc(wb_main_cyc),
                .wb_out_stb(wb_main_stb),
                .wb_out_adr(wb_main_adr),
                .wb_out_we(wb_main_we),
                .wb_out_sel(wb_main_sel),
                .wb_out_dat(wb_main_dat),
                .wb_out_cti(wb_main_cti),
                .wb_out_bte(wb_main_bte),
                .wb_out_ack(wb_main_ack),
                .wb_out_err(wb_main_err),
                .wb_out_rty(wb_main_rty),
                .wb_out_rdt(wb_main_rdt)
            );

            wb_interconnect #(.ADDR_WIDTH(26)) interconnect_memory_devices(
                .wb_in_cyc(wb_main_cyc),
                .wb_in_stb(wb_main_stb),
                .wb_in_adr(wb_main_adr),
                .wb_in_we(wb_main_we),
                .wb_in_sel(wb_main_sel),
                .wb_in_dat(wb_main_dat),
                .wb_in_cti(wb_main_cti),
                .wb_in_bte(wb_main_bte),
                .wb_in_ack(wb_main_ack),
                .wb_in_err(wb_main_err),
                .wb_in_rty(wb_main_rty),
                .wb_in_rdt(wb_main_rdt),

                .wb_out0_cyc(wb_devices_cyc),
                .wb_out0_stb(wb_devices_stb),
                .wb_out0_adr(wb_devices_adr),
                .wb_out0_we(wb_devices_we),
                .wb_out0_sel(wb_devices_sel),
                .wb_out0_dat(wb_devices_dat),
                .wb_out0_cti(wb_devices_cti),
                .wb_out0_bte(wb_devices_bte),
                .wb_out0_ack(wb_devices_ack),
                .wb_out0_err(wb_devices_err),
                .wb_out0_rty(wb_devices_rty),
                .wb_out0_rdt(wb_devices_rdt),

                .wb_out1_cyc(wb_memory_cyc),
                .wb_out1_stb(wb_memory_stb),
                .wb_out1_adr(wb_memory_adr),
                .wb_out1_we(wb_memory_we),
                .wb_out1_sel(wb_memory_sel),
                .wb_out1_dat(wb_memory_dat),
                .wb_out1_cti(wb_memory_cti),
                .wb_out1_bte(wb_memory_bte),
                .wb_out1_ack(wb_memory_ack),
                .wb_out1_err(wb_memory_err),
                .wb_out1_rty(wb_memory_rty),
                .wb_out1_rdt(wb_memory_rdt)
            );
        end else begin
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

                .wb_out0_cyc(wb_devices_cyc),
                .wb_out0_stb(wb_devices_stb),
                .wb_out0_adr(wb_devices_adr),
                .wb_out0_we(wb_devices_we),
                .wb_out0_sel(wb_devices_sel),
                .wb_out0_dat(wb_devices_dat),
                .wb_out0_cti(wb_devices_cti),
                .wb_out0_bte(wb_devices_bte),
                .wb_out0_ack(wb_devices_ack),
                .wb_out0_err(wb_devices_err),
                .wb_out0_rty(wb_devices_rty),
                .wb_out0_rdt(wb_devices_rdt),

                .wb_out1_cyc(wb_memory_cyc),
                .wb_out1_stb(wb_memory_stb),
                .wb_out1_adr(wb_memory_adr),
                .wb_out1_we(wb_memory_we),
                .wb_out1_sel(wb_memory_sel),
                .wb_out1_dat(wb_memory_dat),
                .wb_out1_cti(wb_memory_cti),
                .wb_out1_bte(wb_memory_bte),
                .wb_out1_ack(wb_memory_ack),
                .wb_out1_err(wb_memory_err),
                .wb_out1_rty(wb_memory_rty),
                .wb_out1_rdt(wb_memory_rdt)
            );
        end
    endgenerate

    wb_interconnect #(.ADDR_WIDTH(5)) interconnect_xxx(
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

        .wb_out0_cyc(wb_null_clock_video_ctrl_cyc),
        .wb_out0_stb(wb_null_clock_video_ctrl_stb),
        .wb_out0_adr(wb_null_clock_video_ctrl_adr),
        .wb_out0_we(wb_null_clock_video_ctrl_we),
        .wb_out0_sel(wb_null_clock_video_ctrl_sel),
        .wb_out0_dat(wb_null_clock_video_ctrl_dat),
        .wb_out0_cti(wb_null_clock_video_ctrl_cti),
        .wb_out0_bte(wb_null_clock_video_ctrl_bte),
        .wb_out0_ack(wb_null_clock_video_ctrl_ack),
        .wb_out0_err(wb_null_clock_video_ctrl_err),
        .wb_out0_rty(wb_null_clock_video_ctrl_rty),
        .wb_out0_rdt(wb_null_clock_video_ctrl_rdt),

        .wb_out1_cyc(wb_mul_uart_audio_cyc),
        .wb_out1_stb(wb_mul_uart_audio_stb),
        .wb_out1_adr(wb_mul_uart_audio_adr),
        .wb_out1_we(wb_mul_uart_audio_we),
        .wb_out1_sel(wb_mul_uart_audio_sel),
        .wb_out1_dat(wb_mul_uart_audio_dat),
        .wb_out1_cti(wb_mul_uart_audio_cti),
        .wb_out1_bte(wb_mul_uart_audio_bte),
        .wb_out1_ack(wb_mul_uart_audio_ack),
        .wb_out1_err(wb_mul_uart_audio_err),
        .wb_out1_rty(wb_mul_uart_audio_rty),
        .wb_out1_rdt(wb_mul_uart_audio_rdt)
    );

    wb_interconnect #(.ADDR_WIDTH(4)) interconnect_0xx(
        .wb_in_cyc(wb_null_clock_video_ctrl_cyc),
        .wb_in_stb(wb_null_clock_video_ctrl_stb),
        .wb_in_adr(wb_null_clock_video_ctrl_adr),
        .wb_in_we(wb_null_clock_video_ctrl_we),
        .wb_in_sel(wb_null_clock_video_ctrl_sel),
        .wb_in_dat(wb_null_clock_video_ctrl_dat),
        .wb_in_cti(wb_null_clock_video_ctrl_cti),
        .wb_in_bte(wb_null_clock_video_ctrl_bte),
        .wb_in_ack(wb_null_clock_video_ctrl_ack),
        .wb_in_err(wb_null_clock_video_ctrl_err),
        .wb_in_rty(wb_null_clock_video_ctrl_rty),
        .wb_in_rdt(wb_null_clock_video_ctrl_rdt),

        .wb_out0_cyc(wb_null_clock_cyc),
        .wb_out0_stb(wb_null_clock_stb),
        .wb_out0_adr(wb_null_clock_adr),
        .wb_out0_we(wb_null_clock_we),
        .wb_out0_sel(wb_null_clock_sel),
        .wb_out0_dat(wb_null_clock_dat),
        .wb_out0_cti(wb_null_clock_cti),
        .wb_out0_bte(wb_null_clock_bte),
        .wb_out0_ack(wb_null_clock_ack),
        .wb_out0_err(wb_null_clock_err),
        .wb_out0_rty(wb_null_clock_rty),
        .wb_out0_rdt(wb_null_clock_rdt),

        .wb_out1_cyc(wb_video_ctrl_cyc),
        .wb_out1_stb(wb_video_ctrl_stb),
        .wb_out1_adr(wb_video_ctrl_adr),
        .wb_out1_we(wb_video_ctrl_we),
        .wb_out1_sel(wb_video_ctrl_sel),
        .wb_out1_dat(wb_video_ctrl_dat),
        .wb_out1_cti(wb_video_ctrl_cti),
        .wb_out1_bte(wb_video_ctrl_bte),
        .wb_out1_ack(wb_video_ctrl_ack),
        .wb_out1_err(wb_video_ctrl_err),
        .wb_out1_rty(wb_video_ctrl_rty),
        .wb_out1_rdt(wb_video_ctrl_rdt)
    );

    wb_interconnect #(.ADDR_WIDTH(4)) interconnect_1xx(
        .wb_in_cyc(wb_mul_uart_audio_cyc),
        .wb_in_stb(wb_mul_uart_audio_stb),
        .wb_in_adr(wb_mul_uart_audio_adr),
        .wb_in_we(wb_mul_uart_audio_we),
        .wb_in_sel(wb_mul_uart_audio_sel),
        .wb_in_dat(wb_mul_uart_audio_dat),
        .wb_in_cti(wb_mul_uart_audio_cti),
        .wb_in_bte(wb_mul_uart_audio_bte),
        .wb_in_ack(wb_mul_uart_audio_ack),
        .wb_in_err(wb_mul_uart_audio_err),
        .wb_in_rty(wb_mul_uart_audio_rty),
        .wb_in_rdt(wb_mul_uart_audio_rdt),

        .wb_out0_cyc(wb_mul_cyc),
        .wb_out0_stb(wb_mul_stb),
        .wb_out0_adr(wb_mul_adr),
        .wb_out0_we(wb_mul_we),
        .wb_out0_sel(wb_mul_sel),
        .wb_out0_dat(wb_mul_dat),
        .wb_out0_cti(wb_mul_cti),
        .wb_out0_bte(wb_mul_bte),
        .wb_out0_ack(wb_mul_ack),
        .wb_out0_err(wb_mul_err),
        .wb_out0_rty(wb_mul_rty),
        .wb_out0_rdt(wb_mul_rdt),

        .wb_out1_cyc(wb_uart_audio_cyc),
        .wb_out1_stb(wb_uart_audio_stb),
        .wb_out1_adr(wb_uart_audio_adr),
        .wb_out1_we(wb_uart_audio_we),
        .wb_out1_sel(wb_uart_audio_sel),
        .wb_out1_dat(wb_uart_audio_dat),
        .wb_out1_cti(wb_uart_audio_cti),
        .wb_out1_bte(wb_uart_audio_bte),
        .wb_out1_ack(wb_uart_audio_ack),
        .wb_out1_err(wb_uart_audio_err),
        .wb_out1_rty(wb_uart_audio_rty),
        .wb_out1_rdt(wb_uart_audio_rdt)
    );

    wb_interconnect #(.ADDR_WIDTH(3)) interconnect_00x(
        .wb_in_cyc(wb_null_clock_cyc),
        .wb_in_stb(wb_null_clock_stb),
        .wb_in_adr(wb_null_clock_adr),
        .wb_in_we(wb_null_clock_we),
        .wb_in_sel(wb_null_clock_sel),
        .wb_in_dat(wb_null_clock_dat),
        .wb_in_cti(wb_null_clock_cti),
        .wb_in_bte(wb_null_clock_bte),
        .wb_in_ack(wb_null_clock_ack),
        .wb_in_err(wb_null_clock_err),
        .wb_in_rty(wb_null_clock_rty),
        .wb_in_rdt(wb_null_clock_rdt),

        .wb_out0_cyc(wb_null_cyc),
        .wb_out0_stb(wb_null_stb),
        .wb_out0_adr(wb_null_adr),
        .wb_out0_we(wb_null_we),
        .wb_out0_sel(wb_null_sel),
        .wb_out0_dat(wb_null_dat),
        .wb_out0_cti(wb_null_cti),
        .wb_out0_bte(wb_null_bte),
        .wb_out0_ack(wb_null_ack),
        .wb_out0_err(wb_null_err),
        .wb_out0_rty(wb_null_rty),
        .wb_out0_rdt(wb_null_rdt),

        .wb_out1_cyc(wb_clock_cyc),
        .wb_out1_stb(wb_clock_stb),
        .wb_out1_adr(wb_clock_adr),
        .wb_out1_we(wb_clock_we),
        .wb_out1_sel(wb_clock_sel),
        .wb_out1_dat(wb_clock_dat),
        .wb_out1_cti(wb_clock_cti),
        .wb_out1_bte(wb_clock_bte),
        .wb_out1_ack(wb_clock_ack),
        .wb_out1_err(wb_clock_err),
        .wb_out1_rty(wb_clock_rty),
        .wb_out1_rdt(wb_clock_rdt)
    );

    wb_interconnect #(.ADDR_WIDTH(3)) interconnect_01x(
        .wb_in_cyc(wb_video_ctrl_cyc),
        .wb_in_stb(wb_video_ctrl_stb),
        .wb_in_adr(wb_video_ctrl_adr),
        .wb_in_we(wb_video_ctrl_we),
        .wb_in_sel(wb_video_ctrl_sel),
        .wb_in_dat(wb_video_ctrl_dat),
        .wb_in_cti(wb_video_ctrl_cti),
        .wb_in_bte(wb_video_ctrl_bte),
        .wb_in_ack(wb_video_ctrl_ack),
        .wb_in_err(wb_video_ctrl_err),
        .wb_in_rty(wb_video_ctrl_rty),
        .wb_in_rdt(wb_video_ctrl_rdt),

        .wb_out0_cyc(wb_video_cyc),
        .wb_out0_stb(wb_video_stb),
        .wb_out0_adr(wb_video_adr),
        .wb_out0_we(wb_video_we),
        .wb_out0_sel(wb_video_sel),
        .wb_out0_dat(wb_video_dat),
        .wb_out0_cti(wb_video_cti),
        .wb_out0_bte(wb_video_bte),
        .wb_out0_ack(wb_video_ack),
        .wb_out0_err(wb_video_err),
        .wb_out0_rty(wb_video_rty),
        .wb_out0_rdt(wb_video_rdt),

        .wb_out1_cyc(wb_ctrl_cyc),
        .wb_out1_stb(wb_ctrl_stb),
        .wb_out1_adr(wb_ctrl_adr),
        .wb_out1_we(wb_ctrl_we),
        .wb_out1_sel(wb_ctrl_sel),
        .wb_out1_dat(wb_ctrl_dat),
        .wb_out1_cti(wb_ctrl_cti),
        .wb_out1_bte(wb_ctrl_bte),
        .wb_out1_ack(wb_ctrl_ack),
        .wb_out1_err(wb_ctrl_err),
        .wb_out1_rty(wb_ctrl_rty),
        .wb_out1_rdt(wb_ctrl_rdt)
    );

    wb_interconnect #(.ADDR_WIDTH(3)) interconnect_10x(
        .wb_in_cyc(wb_uart_audio_cyc),
        .wb_in_stb(wb_uart_audio_stb),
        .wb_in_adr(wb_uart_audio_adr),
        .wb_in_we(wb_uart_audio_we),
        .wb_in_sel(wb_uart_audio_sel),
        .wb_in_dat(wb_uart_audio_dat),
        .wb_in_cti(wb_uart_audio_cti),
        .wb_in_bte(wb_uart_audio_bte),
        .wb_in_ack(wb_uart_audio_ack),
        .wb_in_err(wb_uart_audio_err),
        .wb_in_rty(wb_uart_audio_rty),
        .wb_in_rdt(wb_uart_audio_rdt),

        .wb_out0_cyc(wb_uart_cyc),
        .wb_out0_stb(wb_uart_stb),
        .wb_out0_adr(wb_uart_adr),
        .wb_out0_we(wb_uart_we),
        .wb_out0_sel(wb_uart_sel),
        .wb_out0_dat(wb_uart_dat),
        .wb_out0_cti(wb_uart_cti),
        .wb_out0_bte(wb_uart_bte),
        .wb_out0_ack(wb_uart_ack),
        .wb_out0_err(wb_uart_err),
        .wb_out0_rty(wb_uart_rty),
        .wb_out0_rdt(wb_uart_rdt),

        .wb_out1_cyc(wb_audio_cyc),
        .wb_out1_stb(wb_audio_stb),
        .wb_out1_adr(wb_audio_adr),
        .wb_out1_we(wb_audio_we),
        .wb_out1_sel(wb_audio_sel),
        .wb_out1_dat(wb_audio_dat),
        .wb_out1_cti(wb_audio_cti),
        .wb_out1_bte(wb_audio_bte),
        .wb_out1_ack(wb_audio_ack),
        .wb_out1_err(wb_audio_err),
        .wb_out1_rty(wb_audio_rty),
        .wb_out1_rdt(wb_audio_rdt)
    );

    dummy_device #(.ADDR_WIDTH(2)) null_device
    (
        .clk(clk),
        .rst(rst),
        .wb_cyc(wb_null_cyc),
        .wb_stb(wb_null_stb),
        .wb_adr(wb_null_adr),
        .wb_we(wb_null_we),
        .wb_sel(wb_null_sel),
        .wb_dat(wb_null_dat),
        .wb_cti(wb_null_cti),
        .wb_bte(wb_null_bte),
        .wb_ack(wb_null_ack),
        .wb_err(wb_null_err),
        .wb_rty(wb_null_rty),
        .wb_rdt(wb_null_rdt)
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

    dummy_device #(.ADDR_WIDTH(2)) ctrl_device(
        .clk(clk),
        .rst(rst),
        .wb_cyc(wb_ctrl_cyc),
        .wb_stb(wb_ctrl_stb),
        .wb_adr(wb_ctrl_adr),
        .wb_we(wb_ctrl_we),
        .wb_sel(wb_ctrl_sel),
        .wb_dat(wb_ctrl_dat),
        .wb_cti(wb_ctrl_cti),
        .wb_bte(wb_ctrl_bte),
        .wb_ack(wb_ctrl_ack),
        .wb_err(wb_ctrl_err),
        .wb_rty(wb_ctrl_rty),
        .wb_rdt(wb_ctrl_rdt)
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

        dummy_device #(.ADDR_WIDTH(3)) mul_device(
            .clk(clk),
            .rst(rst),
            .wb_cyc(wb_mul_cyc),
            .wb_stb(wb_mul_stb),
            .wb_adr(wb_mul_adr),
            .wb_we(wb_mul_we),
            .wb_sel(wb_mul_sel),
            .wb_dat(wb_mul_dat),
            .wb_cti(wb_mul_cti),
            .wb_bte(wb_mul_bte),
            .wb_ack(wb_mul_ack),
            .wb_err(wb_mul_err),
            .wb_rty(wb_mul_rty),
            .wb_rdt(wb_mul_rdt)
        );

        if (ENABLE_VIDEO) begin
            video_device #(.ADDR_WIDTH(2), .FB_ADDR_WIDTH(26)) video_device(
                .clk(clk),
                .rst(rst),
                .wb_cyc(wb_video_cyc),
                .wb_stb(wb_video_stb),
                .wb_adr(wb_video_adr),
                .wb_we(wb_video_we),
                .wb_sel(wb_video_sel),
                .wb_dat(wb_video_dat),
                .wb_cti(wb_video_cti),
                .wb_bte(wb_video_bte),
                .wb_ack(wb_video_ack),
                .wb_err(wb_video_err),
                .wb_rty(wb_video_rty),
                .wb_rdt(wb_video_rdt),
                .fb_enabled(fb_enabled),
                .fb_addr(fb_addr)
            );
            
            video_renderer #(.ADDR_WIDTH(26)) renderer(
                .clk(clk),
                .rst(rst),

                .config_enabled(fb_enabled),
                .config_addr(fb_addr),

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

                .vga_hsync(vga_hsync),
                .vga_vsync(vga_vsync),
                .vga_red(vga_red),
                .vga_green(vga_green),
                .vga_blue(vga_blue)
            );
        end else begin
            dummy_device #(.ADDR_WIDTH(2)) video_device(
                .clk(clk),
                .rst(rst),
                .wb_cyc(wb_video_cyc),
                .wb_stb(wb_video_stb),
                .wb_adr(wb_video_adr),
                .wb_we(wb_video_we),
                .wb_sel(wb_video_sel),
                .wb_dat(wb_video_dat),
                .wb_cti(wb_video_cti),
                .wb_bte(wb_video_bte),
                .wb_ack(wb_video_ack),
                .wb_err(wb_video_err),
                .wb_rty(wb_video_rty),
                .wb_rdt(wb_video_rdt)
            );

            assign vga_hsync = 1'b1;
            assign vga_vsync = 1'b1;
            assign vga_red = 2'b00;
            assign vga_green = 2'b00;
            assign vga_blue = 2'b00;
        end
    endgenerate


endmodule
