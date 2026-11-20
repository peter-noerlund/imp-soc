`default_nettype none

/**
  Shift-register based register file

  All registers shifts every cycle, so the register_file only accepts requests the ring
  is at the correct position.

  The protocol is as follows:

  For a read/write operation:

  Cycle 0: CPU asserts rf_rreq
  Cycle 1: CPU presents registers on rf_rreg0 and rf_rreg1
  Cycle n: Register file asserts rf_ready. This must happend _after_ cycle 1
  Cycle n+1: Bit/nibbles are read/written

  For a write-only operation:

  Cycle 0: CPU asserts rf_wreq
  Cycle 0+: Register file asserts rf_ready. This can happen at cycle 0
  Cycle 1+: Bit/nibbles are written

  Note that for optimal flow, rf_ready is asserted at the same time as rf_wreq

  This particular register file is a ring buffer, so it only works every 32/8 cycles (depending on mode).
  So rf_rreq will be saved as a pending_req and acted upon when possible
  rf_wreq is acted on immediately if ring is at its end, but otherwise it is saved as a pending_req
  */
module register_file
    #(
        parameter int W=1,
        parameter int B=W-1,
        parameter [0:0] DEBUG=1
    )
    (
        input wire clk,
        input wire rst,

        //! @virtualbus RF @dir input Register File Bus
        input wire          rf_rreq,    //! Read/Write request indicator
        input wire          rf_wreq,    //! Write-only request indicator
        output wire         rf_ready,   //! Ready to respond

        input wire          rf_wen0,    //! Write eanble
        input wire [5:0]    rf_wreg0,   //! Write register
        input wire [B:0]    rf_wdata0,  //! Write data

        input wire          rf_wen1,    //! Write eanble
        input wire [5:0]    rf_wreg1,   //! Write register
        input wire [B:0]    rf_wdata1,  //! Write data

        input wire [5:0]    rf_rreg0,   //! Read register #0
        output wire [B:0]   rf_rdata0,  //! Read data #0

        input wire [5:0]    rf_rreg1,   //! Read register #1
        output wire [B:0]   rf_rdata1   //! Read data #1
        //! @end
    );

    localparam int COUNTER_WIDTH = $clog2(32 / W);
    localparam [COUNTER_WIDTH - 1 : 0] COUNTER_MAX = COUNTER_WIDTH'(32 / W - 1);

    logic [31:0] regs [13:0];
    logic [COUNTER_WIDTH - 1 : 0] cnt;
    logic pending_req;
    wire [B:0] regout [15:0];
    wire [B:0] regout_meip;
    wire [B:0] regout_mtvec;
    wire rreg1_meip;
    wire rreg1_mtvec;

    wire [3:0] rreg0;
    wire [3:0] rreg1;
    wire [4:0] wreg0;

    assign rreg0 = rf_rreg0[3:0];
    assign rreg1 = rf_rreg1[3:0];
    assign wreg0 = {rf_wreg0[5], rf_wreg0[3:0]};

    assign rf_ready = ~rst & (rf_wreq | pending_req) & (cnt == COUNTER_MAX);
    assign rf_rdata0 = regout[rreg0];
    assign rf_rdata1 =
        rreg1_meip ? regout_meip :
        rreg1_mtvec ? regout_mtvec :
        regout[rreg1];

    assign regout[0] = W'(0);           // x0 / zero
    assign regout[1] = regs[0][B:0];    // x1 / ra
    assign regout[2] = regs[1][B:0];    // x2 / sp
    //assign regout[3] = W'(0);           // x3 / gp
    assign regout[4] = W'(0);           // x4 / tp
    assign regout[5] = regs[2][B:0];    // x5 / t0
    assign regout[6] = regs[3][B:0];    // x6 / t1
    assign regout[7] = regs[4][B:0];    // x7 / t2
    assign regout[8] = regs[5][B:0];    // x8 / s0
    assign regout[9] = regs[6][B:0];    // x9 / s1
    assign regout[10] = regs[7][B:0];   // x10 / a0
    assign regout[11] = regs[8][B:0];   // x11 / a1
    assign regout[12] = regs[9][B:0];   // x12 / a2
    assign regout[13] = regs[10][B:0];  // x13 / a3
    assign regout[14] = regs[11][B:0];  // x14 / a4
    assign regout[15] = regs[12][B:0];  // x15 / a5
    assign regout_meip = regs[13][B:0];

    generate
        if (W == 1) begin: gen_gp1
            assign regout[3] = (cnt == COUNTER_WIDTH'(24)) || (cnt == COUNTER_WIDTH'(10));
        end else if (W == 4) begin: gen_gp4
            assign regout[3] =
                (cnt == COUNTER_WIDTH'(6)) ? 4'h1 :
                (cnt == COUNTER_WIDTH'(2)) ? 4'h4 :
                 4'h0;
        end
    endgenerate

    generate
        if (W == 1) begin: gen_mtvec1
            assign regout_mtvec = cnt == COUNTER_WIDTH'(3) ? 1'b1 : 1'b0;
        end else if (W == 4) begin: gen_mtvec4
            assign regout_mtvec = cnt == COUNTER_WIDTH'(0) ? 4'b1000 : 4'b0000;
        end
    endgenerate

    assign rreg1_mtvec = rf_rreg1[5] & ~rf_rreg1[1];
    assign rreg1_meip = rf_rreg1[5] & rf_rreg1[1];

    always_ff @ (posedge clk) begin
        if (rst) begin
            pending_req <= 1'b0;
        end else if (rf_rreq || (rf_wreq && cnt != COUNTER_MAX)) begin
            pending_req <= 1'b1;
        end else if (pending_req && cnt == COUNTER_MAX) begin
            pending_req <= 1'b0;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            cnt <= COUNTER_WIDTH'(0);
        end else begin
            cnt <= cnt + COUNTER_WIDTH'(1);
        end
    end

    always_ff @ (posedge clk) begin
        regs[0] <= {rf_wen0 && wreg0 == 5'd1 ? rf_wdata0 : regs[0][B:0], regs[0][31:W]};
        regs[1] <= {rf_wen0 && wreg0 == 5'd2 ? rf_wdata0 : regs[1][B:0], regs[1][31:W]};
        regs[2] <= {rf_wen0 && wreg0 == 5'd5 ? rf_wdata0 : regs[2][B:0], regs[2][31:W]};
        regs[3] <= {rf_wen0 && wreg0 == 5'd6 ? rf_wdata0 : regs[3][B:0], regs[3][31:W]};
        regs[4] <= {rf_wen0 && wreg0 == 5'd7 ? rf_wdata0 : regs[4][B:0], regs[4][31:W]};
        regs[5] <= {rf_wen0 && wreg0 == 5'd8 ? rf_wdata0 : regs[5][B:0], regs[5][31:W]};
        regs[6] <= {rf_wen0 && wreg0 == 5'd9 ? rf_wdata0 : regs[6][B:0], regs[6][31:W]};
        regs[7] <= {rf_wen0 && wreg0 == 5'd10 ? rf_wdata0 : regs[7][B:0], regs[7][31:W]};
        regs[8] <= {rf_wen0 && wreg0 == 5'd11 ? rf_wdata0 : regs[8][B:0], regs[8][31:W]};
        regs[9] <= {rf_wen0 && wreg0 == 5'd12 ? rf_wdata0 : regs[9][B:0], regs[9][31:W]};
        regs[10] <= {rf_wen0 && wreg0 == 5'd13 ? rf_wdata0 : regs[10][B:0], regs[10][31:W]};
        regs[11] <= {rf_wen0 && wreg0 == 5'd14 ? rf_wdata0 : regs[11][B:0], regs[11][31:W]};
        regs[12] <= {rf_wen0 && wreg0 == 5'd15 ? rf_wdata0 : regs[12][B:0], regs[12][31:W]};
        regs[13] <= {rf_wen1 ? rf_wdata1 : regs[13][B:0], regs[13][31:W]};
    end

    generate
        if (DEBUG) begin: gen_debug
            wire [31:0] x0;
            bit [31:0] x1;
            bit [31:0] x2;
            wire [31:0] x3;
            wire [31:0] x4;
            bit [31:0] x5;
            bit [31:0] x6;
            bit [31:0] x7;
            bit [31:0] x8;
            bit [31:0] x9;
            bit [31:0] x10;
            bit [31:0] x11;
            bit [31:0] x12;
            bit [31:0] x13;
            bit [31:0] x14;
            bit [31:0] x15;

            assign x0 = 32'h00000000;
            assign x3 = 32'h01000400;
            assign x4 = 32'h00000000;

            always_ff @ (posedge clk) begin
                if (cnt == COUNTER_WIDTH'(0)) begin
                    x1 <= regs[0];
                    x2 <= regs[1];
                    x5 <= regs[2];
                    x6 <= regs[3];
                    x7 <= regs[4];
                    x8 <= regs[5];
                    x9 <= regs[6];
                    x10 <= regs[7];
                    x11 <= regs[8];
                    x12 <= regs[9];
                    x13 <= regs[10];
                    x14 <= regs[11];
                    x15 <= regs[12];
                end
            end
        end
    endgenerate

    wire _unused = &{rf_rreg0[5:4], rf_rreg1[4], rf_wreg0[4], rf_wreg1};
endmodule
