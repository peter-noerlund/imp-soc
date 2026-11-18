`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
     that can be driven / tested by the cocotb test.py.
*/
module tb ();
    // Dump the signals to a FST file. You can view it with gtkwave or surfer.
    initial begin
        $dumpfile("tb.fst");
        $dumpvars(0, tb);
        #1;
    end

    // Wire up the inputs and outputs:
    reg clk;
    reg rst_n;
    reg ena;
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    wire spi_sck;
    wire [3:0] spi_sio_out;
    wire [3:0] spi_sio_oe;
    wire [3:0] spi_sio_in;
    wire spi_flash_ss_n;
    wire spi_psram_ss_n;
    wire audio_out;

    wire vga_vsync;
    wire vga_hsync;
    wire [1:0] vga_red;
    wire [1:0] vga_green;
    wire [1:0] vga_blue;

    assign spi_sck          = uio_out[3];
    assign spi_sio_out      = {uio_out[5:4], uio_out[2:1]};
    assign uio_in[5:4]      = spi_sio_in[3:2];
    assign uio_in[2:1]      = spi_sio_in[1:0];
    assign spi_sio_oe       = {uio_oe[5:4], uio_oe[2:1]};
    assign spi_flash_ss_n   = uio_out[0];
    assign spi_psram_ss_n   = uio_out[6];
    assign audio_out        = uio_out[7];

    assign vga_hsync        = io_out[7];
    assign vga_vsync        = io_out[3];
    assign vga_blue         = {io_out[6], io_out[2]};
    assign vga_green        = {io_out[5], io_out[1]};
    assign vga_red          = {io_out[4], io_out[0]};

`ifdef GL_TEST
    wire VPWR = 1'b1;
    wire VGND = 1'b0;
`endif

    // Replace tt_um_example with your module name:
    tt_um_pchri03_imp_soc user_project (

            // Include power ports for the Gate Level test:
`ifdef GL_TEST
            .VPWR(VPWR),
            .VGND(VGND),
`endif

            .ui_in    (ui_in),        // Dedicated inputs
            .uo_out (uo_out),     // Dedicated outputs
            .uio_in (uio_in),     // IOs: Input path
            .uio_out(uio_out),    // IOs: Output path
            .uio_oe (uio_oe),     // IOs: Enable path (active high: 0=input, 1=output)
            .ena        (ena),            // enable - goes high when design is selected
            .clk        (clk),            // clock
            .rst_n    (rst_n)         // not reset
    );

endmodule
