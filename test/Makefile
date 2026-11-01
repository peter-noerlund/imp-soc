all: clock_device register_file uart_device mul_device write_aligner memory_device video_device video_renderer cpu soc

clock_device:
	$(MAKE) -C clock_device

memory_device:
	$(MAKE) -C memory_device

mul_device:
	$(MAKE) -C mul_device

register_file:
	$(MAKE) -C register_file

cpu:
	$(MAKE) -C cpu

soc:
	$(MAKE) -C soc

uart_device:
	$(MAKE) -C uart_device

video_device:
	$(MAKE) -C video_device

video_renderer:
	$(MAKE) -C video_renderer

write_aligner:
	$(MAKE) -C write_aligner

.PHONY: clock_device register_file uart_device mul_device write_aligner memory_device cpu soc video_device video_renderer