`default_nettype none

module soc
    #(
        parameter int ENABLE_TIMER_DEVICE=1,
        parameter int ENABLE_INPUT_DEVICE=1,
        parameter int ENABLE_AUDIO_DEVICE=1,
        parameter int ENABLE_VGA_DEVICE=1,
        parameter int ENABLE_RAW_INPUT=1,
        parameter int GAMEPAD_COUNT=2,
        parameter int ENABLE_4BIT=0,
        parameter int ENABLE_COMPRESSED=0
    )
    (
        input wire clk,
        input wire rst,

        output wire vga_hsync,
        output wire vga_vsync,
        output wire [1:0] vga_red,
        output wire [1:0] vga_green,
        output wire [1:0] vga_blue,

        output wire spi_sck,
        output wire [3:0] spi_sio_out,
        output wire [3:0] spi_sio_oe,
        input wire [3:0] spi_sio_in,
        output wire spi_flash_ss_n,
        output wire spi_psram_ss_n,

        input wire [7:0] input_pmod,
        output wire audio_out
    );

    // Main wishbone bus
    wire wb_cpu_cyc;
    wire wb_cpu_stb;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [31:0] wb_cpu_adr;
    /* verilator lint_on UNUSEDSIGNAL */
    wire wb_cpu_we;
    wire [3:0] wb_cpu_sel;
    wire [31:0] wb_cpu_dat;
    wire [2:0] wb_cpu_cti;
    wire [1:0] wb_cpu_bte;
    wire wb_cpu_ack;
    wire wb_cpu_rty;
    wire wb_cpu_err;
    wire [31:0] wb_cpu_rdt;

    // Memory
    wire wb_cpu_mem_stb;
    wire wb_cpu_mem_ack;
    wire wb_cpu_mem_rty;
    wire wb_cpu_mem_err;
    wire [31:0] wb_cpu_mem_rdt;

    // Clock device
    wire wb_cpu_timer_stb;
    wire wb_cpu_timer_ack;
    wire wb_cpu_timer_rty;
    wire wb_cpu_timer_err;
    wire [31:0] wb_cpu_timer_rdt;

    // Input device
    wire wb_cpu_input_stb;
    wire wb_cpu_input_ack;
    wire wb_cpu_input_rty;
    wire wb_cpu_input_err;
    wire [31:0] wb_cpu_input_rdt;

    // Audio device
    wire wb_cpu_audio_stb;
    wire wb_cpu_audio_ack;
    wire wb_cpu_audio_rty;
    wire wb_cpu_audio_err;
    wire [31:0] wb_cpu_audio_rdt;

    // VGA device
    wire wb_cpu_vga_stb;
    wire wb_cpu_vga_ack;
    wire wb_cpu_vga_rty;
    wire wb_cpu_vga_err;
    wire [31:0] wb_cpu_vga_rdt;

    // Memory bus
    wire wb_mem_cyc;
    wire wb_mem_stb;
    wire [24:0] wb_mem_adr;
    wire wb_mem_we;
    wire [3:0] wb_mem_sel;
    wire [31:0] wb_mem_dat;
    wire [2:0] wb_mem_cti;
    wire [1:0] wb_mem_bte;
    wire wb_mem_ack;
    wire wb_mem_rty;
    wire wb_mem_err;
    wire [31:0] wb_mem_rdt;

    wire irq;

    cpu #(.ENABLE_4BIT(ENABLE_4BIT), .ENABLE_COMPRESSED(ENABLE_COMPRESSED)) cpu(
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
        .wb_rty(wb_cpu_rty),
        .wb_err(wb_cpu_err),
        .wb_rdt(wb_cpu_rdt),

        .irq(irq)
    );

    wb_interconnect #(.ADDR_WIDTH(26)) wb_interconnect(
        .wb_in_stb(wb_cpu_stb),
        .wb_in_adr(wb_cpu_adr[25:0]),
        .wb_in_ack(wb_cpu_ack),
        .wb_in_rty(wb_cpu_rty),
        .wb_in_err(wb_cpu_err),
        .wb_in_rdt(wb_cpu_rdt),

        .wb_mem_stb(wb_cpu_mem_stb),
        .wb_mem_ack(wb_cpu_mem_ack),
        .wb_mem_rty(wb_cpu_mem_rty),
        .wb_mem_err(wb_cpu_mem_err),
        .wb_mem_rdt(wb_cpu_mem_rdt),

        .wb_timer_stb(wb_cpu_timer_stb),
        .wb_timer_ack(wb_cpu_timer_ack),
        .wb_timer_rty(wb_cpu_timer_rty),
        .wb_timer_err(wb_cpu_timer_err),
        .wb_timer_rdt(wb_cpu_timer_rdt),

        .wb_input_stb(wb_cpu_input_stb),
        .wb_input_ack(wb_cpu_input_ack),
        .wb_input_rty(wb_cpu_input_rty),
        .wb_input_err(wb_cpu_input_err),
        .wb_input_rdt(wb_cpu_input_rdt),

        .wb_audio_stb(wb_cpu_audio_stb),
        .wb_audio_ack(wb_cpu_audio_ack),
        .wb_audio_rty(wb_cpu_audio_rty),
        .wb_audio_err(wb_cpu_audio_err),
        .wb_audio_rdt(wb_cpu_audio_rdt),
 
        .wb_vga_stb(wb_cpu_vga_stb),
        .wb_vga_ack(wb_cpu_vga_ack),
        .wb_vga_rty(wb_cpu_vga_rty),
        .wb_vga_err(wb_cpu_vga_err),
        .wb_vga_rdt(wb_cpu_vga_rdt)
    );

    memory_device memory_device(
        .clk(clk),
        .rst(rst),

        .wb_cyc(wb_mem_cyc),
        .wb_stb(wb_mem_stb),
        .wb_adr(wb_mem_adr[24:0]),
        .wb_we(wb_mem_we),
        .wb_sel(wb_mem_sel),
        .wb_dat(wb_mem_dat),
        .wb_cti(wb_mem_cti),
        .wb_bte(wb_mem_bte),
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

    generate
        if (ENABLE_TIMER_DEVICE) begin: timer_device
            timer_device #(.ADDR_WIDTH(3), .COUNTER_WIDTH(19)) timer_device(
                .clk(clk),
                .rst(rst),

                .wb_cyc(wb_cpu_cyc),
                .wb_stb(wb_cpu_timer_stb),
                .wb_adr(wb_cpu_adr[2:0]),
                .wb_we(wb_cpu_we),
                .wb_sel(wb_cpu_sel),
                .wb_dat(wb_cpu_dat),
                .wb_cti(wb_cpu_cti),
                .wb_bte(wb_cpu_bte),
                .wb_ack(wb_cpu_timer_ack),
                .wb_rty(wb_cpu_timer_rty),
                .wb_err(wb_cpu_timer_err),
                .wb_rdt(wb_cpu_timer_rdt),

                .irq_out(irq)
            );
        end else begin: no_timer_device
            dummy_device #(.ADDR_WIDTH(3)) timer_device(
                .clk(clk),
                .rst(rst),

                .wb_cyc(wb_cpu_cyc),
                .wb_stb(wb_cpu_timer_stb),
                .wb_adr(wb_cpu_adr[2:0]),
                .wb_we(wb_cpu_we),
                .wb_sel(wb_cpu_sel),
                .wb_dat(wb_cpu_dat),
                .wb_cti(wb_cpu_cti),
                .wb_bte(wb_cpu_bte),
                .wb_ack(wb_cpu_timer_ack),
                .wb_rty(wb_cpu_timer_rty),
                .wb_err(wb_cpu_timer_err),
                .wb_rdt(wb_cpu_timer_rdt)
            );

            assign irq = 1'b0;
        end
    endgenerate

    generate
        if (ENABLE_INPUT_DEVICE) begin: input_device
            input_device #(.GAMEPAD_COUNT(GAMEPAD_COUNT), .ENABLE_RAW_INPUT(ENABLE_RAW_INPUT), .ADDR_WIDTH(3)) input_device(
                .clk(clk),
                .rst(rst),

                .wb_cyc(wb_cpu_cyc),
                .wb_stb(wb_cpu_input_stb),
                .wb_adr(wb_cpu_adr[2:0]),
                .wb_we(wb_cpu_we),
                .wb_sel(wb_cpu_sel),
                .wb_dat(wb_cpu_dat),
                .wb_cti(wb_cpu_cti),
                .wb_bte(wb_cpu_bte),
                .wb_ack(wb_cpu_input_ack),
                .wb_rty(wb_cpu_input_rty),
                .wb_err(wb_cpu_input_err),
                .wb_rdt(wb_cpu_input_rdt),
            
                .input_pmod(input_pmod)    
            );
        end else begin: no_input_device
            dummy_device #(.ADDR_WIDTH(3)) input_device(
                .clk(clk),
                .rst(rst),

                .wb_cyc(wb_cpu_cyc),
                .wb_stb(wb_cpu_input_stb),
                .wb_adr(wb_cpu_adr[2:0]),
                .wb_we(wb_cpu_we),
                .wb_sel(wb_cpu_sel),
                .wb_dat(wb_cpu_dat),
                .wb_cti(wb_cpu_cti),
                .wb_bte(wb_cpu_bte),
                .wb_ack(wb_cpu_input_ack),
                .wb_rty(wb_cpu_input_rty),
                .wb_err(wb_cpu_input_err),
                .wb_rdt(wb_cpu_input_rdt)
            );

            wire _unused_input = &{input_pmod};
        end
    endgenerate

    generate
        if (ENABLE_AUDIO_DEVICE) begin: audio_device
            audio_device #(.ADDR_WIDTH(3), .COUNTER_WIDTH(18), .RESET_VALUE_WIDTH(16)) audio_device(
                .clk(clk),
                .rst(rst),

                .wb_cyc(wb_cpu_cyc),
                .wb_stb(wb_cpu_audio_stb),
                .wb_adr(wb_cpu_adr[2:0]),
                .wb_we(wb_cpu_we),
                .wb_sel(wb_cpu_sel),
                .wb_dat(wb_cpu_dat),
                .wb_cti(wb_cpu_cti),
                .wb_bte(wb_cpu_bte),
                .wb_ack(wb_cpu_audio_ack),
                .wb_rty(wb_cpu_audio_rty),
                .wb_err(wb_cpu_audio_err),
                .wb_rdt(wb_cpu_audio_rdt),

                .audio_out(audio_out)
            );
        end else begin: no_audio_device
            dummy_device #(.ADDR_WIDTH(3)) audio_device(
                .clk(clk),
                .rst(rst),

                .wb_cyc(wb_cpu_cyc),
                .wb_stb(wb_cpu_audio_stb),
                .wb_adr(wb_cpu_adr[2:0]),
                .wb_we(wb_cpu_we),
                .wb_sel(wb_cpu_sel),
                .wb_dat(wb_cpu_dat),
                .wb_cti(wb_cpu_cti),
                .wb_bte(wb_cpu_bte),
                .wb_ack(wb_cpu_audio_ack),
                .wb_rty(wb_cpu_audio_rty),
                .wb_err(wb_cpu_audio_err),
                .wb_rdt(wb_cpu_audio_rdt)
            );

            assign audio_out = 1'b1;
        end
    endgenerate

    generate
        if (ENABLE_VGA_DEVICE) begin: vga_device
            wire vgaconfig_enabled;
            wire [24:0] vgaconfig_addr;

            wire vgactrl_read_req;
            wire [383:0] vgactrl_memory;

            // VGA Memory bus
            wire wb_vga_cyc;
            wire wb_vga_stb;
            wire [24:0] wb_vga_adr;
            wire wb_vga_we;
            wire [3:0] wb_vga_sel;
            wire [31:0] wb_vga_dat;
            wire [2:0] wb_vga_cti;
            wire [1:0] wb_vga_bte;
            wire wb_vga_ack;
            wire wb_vga_rty;
            wire wb_vga_err;
            wire [31:0] wb_vga_rdt;

            wb_arbiter #(.ADDR_WIDTH(25)) arbiter(
                .clk(clk),
                .rst(rst),
                
                .wb_in0_cyc(wb_vga_cyc),
                .wb_in0_stb(wb_vga_stb),
                .wb_in0_adr(wb_vga_adr),
                .wb_in0_we(wb_vga_we),
                .wb_in0_sel(wb_vga_sel),
                .wb_in0_dat(wb_vga_dat),
                .wb_in0_cti(wb_vga_cti),
                .wb_in0_bte(wb_vga_bte),
                .wb_in0_ack(wb_vga_ack),
                .wb_in0_rty(wb_vga_rty),
                .wb_in0_err(wb_vga_err),
                .wb_in0_rdt(wb_vga_rdt),

                .wb_in1_cyc(wb_cpu_cyc),
                .wb_in1_stb(wb_cpu_mem_stb),
                .wb_in1_adr(wb_cpu_adr[24:0]),
                .wb_in1_we(wb_cpu_we),
                .wb_in1_sel(wb_cpu_sel),
                .wb_in1_dat(wb_cpu_dat),
                .wb_in1_cti(wb_cpu_cti),
                .wb_in1_bte(wb_cpu_bte),
                .wb_in1_ack(wb_cpu_mem_ack),
                .wb_in1_rty(wb_cpu_mem_rty),
                .wb_in1_err(wb_cpu_mem_err),
                .wb_in1_rdt(wb_cpu_mem_rdt),

                .wb_out_cyc(wb_mem_cyc),
                .wb_out_stb(wb_mem_stb),
                .wb_out_adr(wb_mem_adr),
                .wb_out_we(wb_mem_we),
                .wb_out_sel(wb_mem_sel),
                .wb_out_dat(wb_mem_dat),
                .wb_out_cti(wb_mem_cti),
                .wb_out_bte(wb_mem_bte),
                .wb_out_ack(wb_mem_ack),
                .wb_out_rty(wb_mem_rty),
                .wb_out_err(wb_mem_err),
                .wb_out_rdt(wb_mem_rdt)
            );

            vga_device #(.ADDR_WIDTH(25)) vga_device(
                .clk(clk),
                .rst(rst),

                .wb_cyc(wb_cpu_cyc),
                .wb_stb(wb_cpu_vga_stb),
                .wb_adr(wb_cpu_adr[24:0]),
                .wb_we(wb_cpu_we),
                .wb_sel(wb_cpu_sel),
                .wb_dat(wb_cpu_dat),
                .wb_cti(wb_cpu_cti),
                .wb_bte(wb_cpu_bte),
                .wb_ack(wb_cpu_vga_ack),
                .wb_rty(wb_cpu_vga_rty),
                .wb_err(wb_cpu_vga_err),
                .wb_rdt(wb_cpu_vga_rdt),
                
                .vgaconfig_enabled(vgaconfig_enabled),
                .vgaconfig_addr(vgaconfig_addr)
            );

            vga_memory #(.ADDR_WIDTH(25), .WORD_COUNT(16), .WORD_SIZE(24), .LINE_COUNT(96)) vga_memory(
                .clk(clk),
                .rst(rst),

                .vgaconfig_addr(vgaconfig_addr),
                .vgactrl_read_req(vgactrl_read_req),
                .vgactrl_memory(vgactrl_memory),

                .wb_cyc(wb_vga_cyc),
                .wb_stb(wb_vga_stb),
                .wb_adr(wb_vga_adr),
                .wb_we(wb_vga_we),
                .wb_sel(wb_vga_sel),
                .wb_cti(wb_vga_cti),
                .wb_bte(wb_vga_bte),
                .wb_dat(wb_vga_dat),
                .wb_ack(wb_vga_ack),
                .wb_rty(wb_vga_rty),
                .wb_err(wb_vga_err),
                .wb_rdt(wb_vga_rdt)
            );

            vga_renderer #(.CHUNK_COUNT(16)) vga_renderer(
                .clk(clk),
                .rst(rst),

                .vgaconfig_enabled(vgaconfig_enabled),

                .vgactrl_read_req(vgactrl_read_req),
                .vgactrl_memory(vgactrl_memory),

                .vga_hsync(vga_hsync),
                .vga_vsync(vga_vsync),
                .vga_red(vga_red),
                .vga_green(vga_green),
                .vga_blue(vga_blue)
            );
        end else begin: no_vga_device
            assign wb_mem_cyc = wb_cpu_cyc;
            assign wb_mem_stb = wb_cpu_mem_stb;
            assign wb_mem_adr = wb_cpu_adr[24:0];
            assign wb_mem_we = wb_cpu_we;
            assign wb_mem_sel = wb_cpu_sel;
            assign wb_mem_dat = wb_cpu_dat;
            assign wb_mem_cti = wb_cpu_cti;
            assign wb_mem_bte = wb_cpu_bte;
            assign wb_cpu_mem_ack = wb_mem_ack;
            assign wb_cpu_mem_rty = wb_mem_rty;
            assign wb_cpu_mem_err = wb_mem_err;
            assign wb_cpu_mem_rdt = wb_mem_rdt;

            assign vga_red = 2'b00;
            assign vga_green = 2'b00;
            assign vga_blue = 2'b00;
            assign vga_vsync = 1'b0;
            assign vga_hsync = 1'b0;

            dummy_device #(.ADDR_WIDTH(3)) vga_device(
                .clk(clk),
                .rst(rst),

                .wb_cyc(wb_cpu_cyc),
                .wb_stb(wb_cpu_vga_stb),
                .wb_adr(wb_cpu_adr[2:0]),
                .wb_we(wb_cpu_we),
                .wb_sel(wb_cpu_sel),
                .wb_dat(wb_cpu_dat),
                .wb_cti(wb_cpu_cti),
                .wb_bte(wb_cpu_bte),
                .wb_ack(wb_cpu_vga_ack),
                .wb_rty(wb_cpu_vga_rty),
                .wb_err(wb_cpu_vga_err),
                .wb_rdt(wb_cpu_vga_rdt)
            );            
        end
    endgenerate
endmodule
