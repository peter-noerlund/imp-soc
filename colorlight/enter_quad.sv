`default_nettype none

module enter_quad
    (
        input wire clk25,

        output wire LED,
        inout wire [7:0] P3_PMOD2
    );

    wire clk;
    wire clk_locked;
    wire rst;

    wire miso;
    bit sck;
    bit mosi;
    bit ss_n;
    
    wire [7:0] p3_pmod2_in;
    wire [7:0] p3_pmod2_oe;
    wire [7:0] p3_pmod2_out;

    wire [7:0] command;

    bit [3:0] state;

    assign LED = rst;

    assign p3_pmod2_oe = 8'b11001011;
    assign p3_pmod2_out = {1'b1, ss_n, 3'b000, sck, 1'b0, mosi, 1'b1};

    assign miso = p3_pmod2_in[2];

    assign command = 8'h35;

    pll pll(
        .clkin(clk25),
        .clkout0(clk),
        .locked(clk_locked)
    );

    reset_handler reset_handler(
        .clk(clk),
        .rst_in(clk_locked),
        .rst_out(rst)
    );

    BB bb[7:0] (
        .B(P3_PMOD2),
        .O(p3_pmod2_in),
        .T(~p3_pmod2_oe),
        .I(p3_pmod2_out)
    );

    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= 4'd0;
            sck <= 1'b0;
            ss_n <= 1'b1;
        end else begin
            if (!ss_n) begin
                sck <= ~sck;
            end

            case (state)
                4'd0: begin
                    ss_n <= 1'b0;
                    mosi <= command[7];
                end

                4'd2: if (sck) begin
                    mosi <= command[6];
                end

                4'd3: if (sck) begin
                    mosi <= command[5];
                end

                4'd4: if (sck) begin
                    mosi <= command[4];
                end

                4'd5: if (sck) begin
                    mosi <= command[3];
                end

                4'd6: if (sck) begin
                    mosi <= command[2];
                end

                4'd7: if (sck) begin
                    mosi <= command[1];
                end

                4'd8: if (sck) begin
                    mosi <= command[0];
                end

                4'd9: if (sck) begin
                    ss_n <= 1'b1;
                end
            endcase

            if (!sck && state != 4'd10) begin
                state <= state + 4'd1;
            end
        end
    end
endmodule
