`default_nettype none

module vga_latch
    #(
        parameter int WIDTH=32
    )
    (
        input wire clk,

        input wire gate,
        input wire [WIDTH - 1 : 0] data_in,
        output wire [WIDTH - 1 : 0] data_out
    );

    bit [WIDTH - 1 : 0] data;
    assign data_out = data;

`ifdef FPGA
    always_ff @ (posedge clk) begin
        if (gate) begin
            data <= data_in;
        end
    end
`else
    always_latch begin
        if (gate) begin
            data = data_in;
        end
    end

    wire _unused = clk;
`endif
endmodule

