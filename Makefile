VERILOG_SOURCES=\
	src/clock_device.sv \
	src/cpu.sv \
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
	src/tt_um_pchri03_imp_soc.v \
	src/vga_device.sv \
    src/vga_latch.sv \
	src/vga_memory.sv \
	src/vga_renderer.sv \
	src/vga_timing.sv \
	src/wb_arbiter.sv \
	src/wb_interconnect.sv \
	src/write_aligner.sv

all: lint

fpga: pico_ice/pico_ice.bin pico_ice/pico_ice_timing.txt

pico_ice/pico_ice_pll.v:
	icepll -q -i 48 -o 25.075 -p -m -f $@

pico_ice/pico_ice.json: $(VERILOG_SOURCES) pico_ice/pico_ice_top.sv pico_ice/pico_ice_pll.v
	yosys -q -p "synth_ice40 -device u -top pico_ice_top -dff -retime -spram -dsp -noabc9 -abc2 -json $@" -DFPGA -DPICO_ICE -l pico_ice/pico_ice.log $^

pico_ice/pico_ice.asc: pico_ice/pico_ice.pcf pico_ice/pico_ice.json
	nextpnr-ice40 -q --up5k --package sg48 --freq 25.075 --asc $@ --json pico_ice/pico_ice.json --pcf pico_ice/pico_ice.pcf

pico_ice/pico_ice.bin: pico_ice/pico_ice.asc
	icepack $^ $@

pico_ice/pico_ice_timing.txt: pico_ice/pico_ice.asc pico_ice/pico_ice.pcf
	icetime -p pico_ice/pico_ice.pcf -r $@ -d up5k -c 25.075 pico_ice/pico_ice.asc

src/config_merged.json: src/config.json info.yaml
	./tt/tt-tool.py --create-user-config

harden:
	./tt/tt_tool.py --create-user-config
	./tt/tt_tool.py --harden
	./tt/tt_tool.py --print-warnings > summary.md
	./tt/tt_tool.py --print-stats >> summary.md
	./tt/tt_tool.py --print-cell-summary >> summary.md
	./tt/tt_tool.py --print-cell-category >> summary.md

lint:
	verilator --lint-only -Wall $(VERILOG_SOURCES)

test:
	$(MAKE) -C test

.PHONY: all fpga harden lint test
