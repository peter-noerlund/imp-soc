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

`ifdef SCL_sky130_fd_sc_hd
    /* verilator lint_off PINMISSING */
    genvar i;
    generate
        for (i = 0; i != WIDTH; i++) begin
            sky130_fd_sc_hd__dlxtp_1 mem(.Q(data_out[i]), .D(data_in[i]), .GATE(gate));
        end
    endgenerate
    /* verilator lint_on PINMISSING */
`else
    bit [WIDTH - 1 : 0] data;

    assign data_out = data;

    always_ff @ (posedge clk) begin
        if (gate) begin
            data <= data_in;
        end
    end
`endif
endmodule

