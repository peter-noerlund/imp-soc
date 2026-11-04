`default_nettype none

module register_file
	#(
		parameter int W=4,
		parameter int B=W-1
	)
    (
        input wire clk,
        input wire rst,

        //! @virtualbus RF @dir input Register File Bus
        input wire          rf_rreq,    //! Read/Write request indicator
        input wire          rf_wreq,    //! Write-only request indicator
        output wire         rf_ready,   //! Ready to respond

        input wire          rf_wen0,    //! Write enable #0
        input wire [5:0]    rf_wreg0,   //! Write register #0
        input wire [B:0]    rf_wdata0,  //! Write data #0

        input wire          rf_wen1,    //! Write enable #1
        input wire [5:0]    rf_wreg1,   //! Write enable #1
        input wire [B:0]    rf_wdata1,  //! Write data #0

        input wire [5:0]    rf_rreg0,   //! Read register #0
        output wire [B:0]   rf_rdata0,  //! Read data #0

        input wire [5:0]    rf_rreg1,   //! Read register #1
        output wire [B:0]   rf_rdata1   //! Read data #1
        //! @end
    );

	generate
		if (W == 1) begin: gen_w1
			register_file_1 impl(
				.clk(clk),
				.rst(rst),
				.rf_rreq(rf_rreq),
				.rf_wreq(rf_wreq),
				.rf_ready(rf_ready),
				.rf_wen0(rf_wen0),
				.rf_wreg0(rf_wreg0),
				.rf_wdata0(rf_wdata0),
				.rf_wen1(rf_wen1),
				.rf_wreg1(rf_wreg1),
				.rf_wdata1(rf_wdata1),
				.rf_rreg0(rf_rreg0),
				.rf_rdata0(rf_rdata0),
				.rf_rreg1(rf_rreg1),
				.rf_rdata1(rf_rdata1)
			);
		end else if (W == 4) begin: gen_w4
			register_file_4 impl(
				.clk(clk),
				.rst(rst),
				.rf_rreq(rf_rreq),
				.rf_wreq(rf_wreq),
				.rf_ready(rf_ready),
				.rf_wen0(rf_wen0),
				.rf_wreg0(rf_wreg0),
				.rf_wdata0(rf_wdata0),
				.rf_wen1(rf_wen1),
				.rf_wreg1(rf_wreg1),
				.rf_wdata1(rf_wdata1),
				.rf_rreg0(rf_rreg0),
				.rf_rdata0(rf_rdata0),
				.rf_rreg1(rf_rreg1),
				.rf_rdata1(rf_rdata1)
			);
		end
	endgenerate
endmodule
