all: audio_device timer_device write_aligner memory_device register_file cpu vga_timing vga_memory vga_device soc

audio_device:
	$(MAKE) -C audio_device

cpu:
	$(MAKE) -C cpu

memory_device:
	$(MAKE) -C memory_device

register_file:
	$(MAKE) -C register_file

soc:
	$(MAKE) -C soc

timer_device:
	$(MAKE) -C timer_device

vga_device:
	$(MAKE) -C vga_device

vga_memory:
	$(MAKE) -C vga_memory

vga_timing:
	$(MAKE) -C vga_timing

write_aligner:
	$(MAKE) -C write_aligner

.PHONY: audio_device cpu memory_device register_file soc timer_device vga_device vga_memory vga_timing
