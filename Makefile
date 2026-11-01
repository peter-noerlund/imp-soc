VERILOG_SOURCES=\
	src/clock_device.sv \
	src/cpu.sv \
    src/dummy_device.sv \
    src/memory_device.sv \
    src/register_file.sv \
	src/serv/rtl/serv_alu.v \
	src/serv/rtl/serv_bufreg.v \
	src/serv/rtl/serv_bufreg2.v \
	src/serv/rtl/serv_ctrl.v \
	src/serv/rtl/serv_csr.v \
	src/serv/rtl/serv_decode.v \
	src/serv/rtl/serv_immdec.v \
	src/serv/rtl/serv_mem_if.v \
	src/serv/rtl/serv_rf_if.v \
	src/serv/rtl/serv_state.v \
	src/serv/rtl/serv_top.v \
	src/serv/servile/servile_arbiter.v \
    src/soc.sv \
    src/tt_um_pchri03_imp_soc.sv \
    src/uart_device.sv \
    src/video_device.sv \
    src/video_renderer.sv \
    src/wb_arbiter.sv \
    src/wb_interconnect.sv \
    src/write_aligner.sv

all:

fpga:
	$(MAKE) -C fpga

src/config_merged.json: src/config.json info.yaml
	./tt-support-tools/tt-tool.py --create-user-config

harden:
	./tt-support-tools/tt_tool.py --create-user-config
	./tt-support-tools/tt_tool.py --harden

lint:
	verilator --lint-only $(VERILOG_SOURCES)

test:
	$(MAKE) -C test

.PHONY: all fpga harden lint test