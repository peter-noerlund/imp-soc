# The simulator we want to run our tests with.
SIM = icarus

# The top-level language of the design (verilog or vhdl).
TOPLEVEL_LANG = verilog

# List of Verilog source files.

VERILOG_SOURCES =  \
	$(CURDIR)/../../src/cpu.sv \
    $(CURDIR)/../../src/register_file.sv \
    $(CURDIR)/../../src/serv/rtl/serv_alu.v \
    $(CURDIR)/../../src/serv/rtl/serv_bufreg.v \
    $(CURDIR)/../../src/serv/rtl/serv_bufreg2.v \
    $(CURDIR)/../../src/serv/rtl/serv_csr.v \
    $(CURDIR)/../../src/serv/rtl/serv_ctrl.v \
    $(CURDIR)/../../src/serv/rtl/serv_debug.v \
    $(CURDIR)/../../src/serv/rtl/serv_decode.v \
    $(CURDIR)/../../src/serv/rtl/serv_immdec.v \
    $(CURDIR)/../../src/serv/rtl/serv_mem_if.v \
    $(CURDIR)/../../src/serv/rtl/serv_rf_if.v \
    $(CURDIR)/../../src/serv/rtl/serv_rf_ram_if.v \
    $(CURDIR)/../../src/serv/rtl/serv_rf_ram.v \
    $(CURDIR)/../../src/serv/rtl/serv_state.v \
    $(CURDIR)/../../src/serv/rtl/serv_top.v \
    $(CURDIR)/../../src/serv/servile/servile_arbiter.v

# The name of the toplevel module/entity in your design.
TOPLEVEL = cpu

# The Python modules which contain your testcases.
# The current directory is included in the Python path,
# so you can just specify the module name without the .py extension.
COCOTB_TEST_MODULES = cpu_tests

# Enable waveform generation.
WAVES = 1

export PYTHONPATH = $(CURDIR)/../

# Includes cocotb's Makefiles which define the build and simulation flows for each supported simulator.
# This must be included *after* all of the variables above are defined.
include $(shell cocotb-config --makefiles)/Makefile.sim
