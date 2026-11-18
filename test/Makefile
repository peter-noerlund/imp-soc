# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
FST ?= -fst # Use more efficient FST format
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(CURDIR)/../src
PROJECT_SOURCES = \
				  tt_um_pchri03_imp_soc.v \
				  audio_device.sv \
				  cpu.sv \
				  input_device.sv \
				  memory_device.sv \
				  register_file.sv \
				  serv/rtl/serv_aligner.v \
				  serv/rtl/serv_alu.v \
				  serv/rtl/serv_bufreg.v \
				  serv/rtl/serv_bufreg2.v \
				  serv/rtl/serv_ctrl.v \
				  serv/rtl/serv_csr.v \
				  serv/rtl/serv_decode.v \
				  serv/rtl/serv_immdec.v \
				  serv/rtl/serv_mem_if.v \
				  serv/rtl/serv_rf_if.v \
				  serv/rtl/serv_state.v \
				  serv/rtl/serv_top.v \
				  serv/servile/servile_arbiter.v \
				  soc.sv \
				  timer_device.sv \
				  vga_device.sv \
				  vga_memory.sv \
				  vga_renderer.sv \
				  vga_timing.sv \
				  wb_arbiter.sv \
				  wb_interconnect.sv \
				  write_aligner.sv

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD		= sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

# Gate level simulation:
SIM_BUILD		= sim_build/gl
COMPILE_ARGS	+= -DGL_TEST
COMPILE_ARGS	+= -DFUNCTIONAL
COMPILE_ARGS	+= -DUSE_POWER_PINS
COMPILE_ARGS	+= -DSIM
COMPILE_ARGS	+= -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# List test modules to run, separated by commas and without the .py suffix:
COCOTB_TEST_MODULES = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

app/test.bin: app/test.elf
	riscv64-unknown-elf-objcopy -O binary $^ $@

app/test.elf: app/test.c app/test.ld app/init.S
	riscv64-unknown-elf-gcc -march=rv32ezicsr -mabi=ilp32e -mstrict-align -mcmodel=medany -mtune=size -mno-relax -Wl,-no-relax -fno-builtin -O3 -Wall -o $@ --specs=/usr/lib/picolibc/riscv64-unknown-elf/picolibc.specs -Wl,-e_init -Tapp/test.ld -DNDEBUG app/test.c app/init.S
