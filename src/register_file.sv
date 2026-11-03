`default_nettype none

module register_file
    #(
        parameter int W=1,
        parameter int B=W-1
    )
    (
        input wire clk,
        input wire rst,

        //! @virtualbus RF @dir input Register File Bus
        input wire          rf_rreq,    //! Read/Write request indicator
        input wire          rf_wreq,    //! Write-only request indicator
        output wire         rf_ready,   //! Ready to respond
        input wire          rf_wen0,    //! Write eanble
        input wire [3:0]    rf_wreg0,   //! Write register
        input wire [B:0]    rf_wdata0,  //! Write data
        input wire [3:0]    rf_rreg0,   //! Read register #0
        output wire [B:0]   rf_rdata0,  //! Read data #0
        input wire [3:0]    rf_rreg1,   //! Read register #1
        output wire [B:0]   rf_rdata1   //! Read data #1
        //! @end
    );

    logic [31:0] regs [12:0];
    logic active;
    logic [4:0] cnt;
    logic ready;
    wire [W * 16 - 1 : 0] regout;

    genvar i;

    assign rf_ready = ready || rf_wreq;
    assign rf_rdata0 = regout[rf_rreg0 * W + B -: W];
    assign rf_rdata1 = regout[rf_rreg1 * W + B -: W];

    assign regout[0 * W + B -: W] = W'(0);           // x0 / zero
    assign regout[1 * W + B -: W] = regs[0][B:0];    // x1 / ra
    assign regout[2 * W + B -: W] = regs[1][B:0];    // x2 / sp
    assign regout[3 * W + B -: W] = W'(0);           // x3 / gp
    assign regout[4 * W + B -: W] = W'(0);           // x4 / tp

    generate
        for (i = 5; i != 16; i++) begin: gen_regout
            assign regout[i * W + B -: W] = regs[i - 3][B:0];
        end
    endgenerate

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

    generate
        for (i = 0; i != 13; ++i) begin: gen_shift
            always_ff @ (posedge clk) begin
                if (!rst && active) begin
                    regs[i] <= {rf_wen0 && rf_wreg0 == 4'd1 ? rf_wdata0 : regs[i][B:0], regs[i][31:W]};
                end
            end
        end
    endgenerate
endmodule
