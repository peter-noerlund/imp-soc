VERILOG_SOURCES=\
	src/audio_device.sv \
	src/cpu.sv \
	src/input_device.sv \
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
	src/timer_device.sv \
	src/tt_um_pchri03_imp_soc.v \
	src/vga_device.sv \
	src/vga_memory.sv \
	src/vga_renderer.sv \
	src/vga_timing.sv \
	src/wb_arbiter.sv \
	src/wb_interconnect.sv \
	src/write_aligner.sv

all: lint

fpga: colorlight/colorlight.svf pico_ice/pico_ice.bin pico_ice/pico_ice_timing.txt

colorlight/pll.v:
	ecppll -i 25 -o 65 -f colorlight/pll.v

colorlight/colorlight.json: $(VERILOG_SOURCES) colorlight/colorlight_top.sv colorlight/pll.v
	yosys -q -p "synth_ecp5 -top colorlight_top -json $@" -DFPGA -DCOLORLIGHT -l colorlight/colorlight.log $^

colorlight/colorlight_out.config: colorlight/colorlight.json
	nextpnr-ecp5 --25k --package CABGA381 --speed 6 --json $^ --textcfg $@ --lpf colorlight/colorlight.lpf --freq 65

colorlight/colorlight.bit: colorlight/colorlight_out.config
	ecppack --svf colorlight/colorlight.svf $^ $@

colorlight/colorlight.svf: colorlight/colorlight.bit

src/config_merged.json: src/config.json info.yaml
	./tt/tt_tool.py --create-user-config

harden: src/config_merged.json
	./tt/tt_tool.py --harden
	./tt/tt_tool.py --print-warnings > summary.md
	./tt/tt_tool.py --print-stats >> summary.md
	./tt/tt_tool.py --print-cell-summary >> summary.md
	./tt/tt_tool.py --print-cell-category >> summary.md

program-colorlight: colorlight/colorlight.svf
	openocd -f colorlight/openocd.cfg

lint:
	verilator --lint-only -Wall $(VERILOG_SOURCES)

lint-colorlight: colorlight/pll.v
	verilator --lint-only -Wall -DFPGA -DCOLORLIGHT --top colorlight_top $(VERILOG_SOURCES) colorlight/colorlight_top.sv colorlight/mock/pll.v colorlight/mock/BB.v

test:
	$(MAKE) -C test

.PHONY: all fpga harden lint lint-colorlight test
