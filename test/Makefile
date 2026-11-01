all: clock_device register_file uart_device mul_device write_aligner memory_device vga_timing cpu soc

clock_device:
	$(MAKE) -C clock_device

memory_device:
	$(MAKE) -C memory_device

register_file:
	$(MAKE) -C register_file

cpu:
	$(MAKE) -C cpu

soc:
	$(MAKE) -C soc

uart_device:
	$(MAKE) -C uart_device

vga_device:
	$(MAKE) -C vga_device

vga_memory:
	$(MAKE) -C vga_memory

vga_timing:
	$(MAKE) -C vga_timing

write_aligner:
	$(MAKE) -C write_aligner

.PHONY: clock_device register_file uart_device mul_device write_aligner memory_device cpu soc vga_device vga_memory vga_timing