`default_nettype none

module register_file
    (
        input wire clk,
        input wire rst,

        //! @virtualbus RF @dir input Register File Bus
        input wire          rf_rreq,    //! Read/Write request indicator
        input wire          rf_wreq,    //! Write-only request indicator
        output wire         rf_ready,   //! Ready to respond
        input wire          rf_wen0,    //! Write eanble
        input wire [3:0]    rf_wreg0,   //! Write register
        input wire          rf_wdata0,  //! Write data
        input wire [3:0]    rf_rreg0,   //! Read register #0
        output wire         rf_rdata0,  //! Read data #0
        input wire [3:0]    rf_rreg1,   //! Read register #1
        output wire         rf_rdata1   //! Read data #1
        //! @end
    );

    logic [31:0] regs [12:0];
    logic active;
    logic [4:0] cnt;
    wire [15:0] rdata;
    logic ready;
    wire [15:0] regout;

    genvar i;

    assign rf_ready = ready || rf_wreq;
    assign rf_rdata0 = regout[rf_rreg0];
    assign rf_rdata1 = regout[rf_rreg1];

    assign regout[0] = 1'b0;            // x0 / zero
    assign regout[1] = regs[0][0];      // x1 / ra
    assign regout[2] = regs[1][0];      // x2 / sp
    assign regout[3] = 1'b0;            // x3 / gp
    assign regout[4] = 1'b0;            // x4 / tp
    assign regout[5] = regs[2][0];      // x5 / t0
    assign regout[6] = regs[3][0];      // x6 / t1
    assign regout[7] = regs[4][0];      // x7 / t2
    assign regout[8] = regs[5][0];      // x8 / s0
    assign regout[9] = regs[6][0];      // x9 / s1
    assign regout[10] = regs[7][0];     // x10 / a0
    assign regout[11] = regs[8][0];     // x11 / a1
    assign regout[12] = regs[9][0];     // x12 / a2
    assign regout[13] = regs[10][0];    // x13 / a3
    assign regout[14] = regs[11][0];    // x14 / a4
    assign regout[15] = regs[12][0];    // x15 / a5

    always_ff @ (posedge clk) begin
        if (rst) begin
            active <= 1'b0;
        end else if (ready || rf_wreq) begin
            active <= 1'b1;
        end else if (cnt == 5'd31) begin
            active <= 1'b0;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            ready <= 1'b0;
        end else if (!ready && rf_rreq) begin
            ready <= 1'b1;
        end else begin
            ready <= 1'b0;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            cnt <= 5'd0;
        end else if (active) begin
            cnt <= cnt + 5'd1;
        end
    end

    always_ff @ (posedge clk) begin
        if (!rst && active) begin
            regs[0] <= {rf_wen0 && rf_wreg0 == 4'd1 ? rf_wdata0 : regs[0][0], regs[0][31:1]};
            regs[1] <= {rf_wen0 && rf_wreg0 == 4'd2 ? rf_wdata0 : regs[1][0], regs[1][31:1]};
            regs[2] <= {rf_wen0 && rf_wreg0 == 4'd5 ? rf_wdata0 : regs[2][0], regs[2][31:1]};
            regs[3] <= {rf_wen0 && rf_wreg0 == 4'd6 ? rf_wdata0 : regs[3][0], regs[3][31:1]};
            regs[4] <= {rf_wen0 && rf_wreg0 == 4'd7 ? rf_wdata0 : regs[4][0], regs[4][31:1]};
            regs[5] <= {rf_wen0 && rf_wreg0 == 4'd8 ? rf_wdata0 : regs[5][0], regs[5][31:1]};
            regs[6] <= {rf_wen0 && rf_wreg0 == 4'd9 ? rf_wdata0 : regs[6][0], regs[6][31:1]};
            regs[7] <= {rf_wen0 && rf_wreg0 == 4'd10 ? rf_wdata0 : regs[7][0], regs[7][31:1]};
            regs[8] <= {rf_wen0 && rf_wreg0 == 4'd11 ? rf_wdata0 : regs[8][0], regs[8][31:1]};
            regs[9] <= {rf_wen0 && rf_wreg0 == 4'd12 ? rf_wdata0 : regs[9][0], regs[9][31:1]};
            regs[10] <= {rf_wen0 && rf_wreg0 == 4'd13 ? rf_wdata0 : regs[10][0], regs[10][31:1]};
            regs[11] <= {rf_wen0 && rf_wreg0 == 4'd14 ? rf_wdata0 : regs[11][0], regs[11][31:1]};
            regs[12] <= {rf_wen0 && rf_wreg0 == 4'd15 ? rf_wdata0 : regs[12][0], regs[12][31:1]};
        end
    end
endmodule
