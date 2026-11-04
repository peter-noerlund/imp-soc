all: audio_device clock_device write_aligner memory_device register_file cpu vga_timing vga_memory vga_device soc

audio_device:
	$(MAKE) -C audio_device

clock_device:
	$(MAKE) -C clock_device

cpu:
	$(MAKE) -C cpu

memory_device:
	$(MAKE) -C memory_device

register_file:
	$(MAKE) -C register_file

soc:
	$(MAKE) -C soc

vga_device:
	$(MAKE) -C vga_device

vga_memory:
	$(MAKE) -C vga_memory

vga_timing:
	$(MAKE) -C vga_timing

write_aligner:
	$(MAKE) -C write_aligner

.PHONY: audio_device clock_device cpu memory_device register_file soc vga_device vga_memory vga_timing
