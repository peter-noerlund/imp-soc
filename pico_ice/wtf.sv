module out
    (
        input wire clk,
        output wire LED_G;
    );

    wire \soc.g;
    wire [3:0] \soc.g_SB_DFFESR_Q_E ;

    SB_LUT4 #(
        .LUT_INIT(16'h00ff)
    ) LED_G_SB_LUT4_O (
        .I0(1'h0),
        .I1(1'h0),
        .I2(1'h0),
        .I3(\soc.g ),
        .O(LED_G)
    );

    SB_DFFESR \soc.g_SB_DFFESR_Q  (
        .C(clk),
        .D(1'h1),
        .E(\soc.g_SB_DFFESR_Q_E [3]),
        .Q(\soc.g ),
        .R(SW2_SB_LUT4_I2_O_SB_DFFSR_D_Q_SB_LUT4_I3_O)
    );

    SB_LUT4 #(
        .LUT_INIT(16'hf333)
    ) \soc.g_SB_DFFESR_Q_E_SB_LUT4_O  (
        .I0(1'h0),
        .I1(SW2_SB_LUT4_I2_O_SB_DFFSR_D_Q[1]),
        .I2(\soc.cpu.serv.state.ibus_cyc_SB_LUT4_I3_2_O [2]),
        .I3(\soc.led_device.ack_SB_LUT4_I2_I3 [1]),
        .O(\soc.g_SB_DFFESR_Q_E [3])
    );
endmodule