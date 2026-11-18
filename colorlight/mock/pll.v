module pll
    (
        input clkin,
        output clkout0,
        output locked
    );

    reg locked_reg;

    assign clkout0 = clkin;
    assign locked = locked_reg;

    initial begin
        locked_reg = 1'b0;
    end

    always @ (posedge clkin) begin
        locked_reg <= 1'b1;
    end
endmodule
