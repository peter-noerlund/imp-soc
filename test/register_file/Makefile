# The simulator we want to run our tests with.
SIM = icarus

# The top-level language of the design (verilog or vhdl).
TOPLEVEL_LANG = verilog

# List of Verilog source files.
VERILOG_SOURCES = $(CURDIR)/../../src/register_file.sv  $(CURDIR)/../../src/register_file_1.sv  $(CURDIR)/../../src/register_file_4.sv

# The name of the toplevel module/entity in your design.
TOPLEVEL = register_file

# The Python modules which contain your testcases.
# The current directory is included in the Python path,
# so you can just specify the module name without the .py extension.
COCOTB_TEST_MODULES = register_file_tests

# Enable waveform generation.
WAVES = 1

# Includes cocotb's Makefiles which define the build and simulation flows for each supported simulator.
# This must be included *after* all of the variables above are defined.
include $(shell cocotb-config --makefiles)/Makefile.sim
