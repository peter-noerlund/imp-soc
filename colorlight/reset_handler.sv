`default_nettype none

module reset_handler
    (
        input wire clk,
        input wire clk_locked,
        output wire rst_out
    );

    bit [3:0] rst_cnt;
    bit rst;

    assign rst_out = rst;

    initial begin
        rst = 1'b1;
        rst_cnt = 4'd0;
    end

    always_ff @ (posedge clk) begin
        if (clk_locked) begin
            if (rst_cnt == 4'd15) begin
                rst <= 1'b0;
            end else begin
                rst_cnt <= rst_cnt + 4'd1;
            end
        end
    end
endmodule
