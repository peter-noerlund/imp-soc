# Installing

Installing 

```python
from machine import Pin
import ice
fpga = ice.fpga(cdone=Pin(26), clock=Pin(24), creset=Pin(27), cram_cs=Pin(9), cram_mosi=Pin(8), cram_sck=Pin(10), frequency=48)
file = open("pico_ice.bin", "br")
fpga.start()
fpga.cram(file)
```

```python
from machine import Pin
import ice
file = open("pico_ice.bin", "br")
flash = ice.flash(miso=Pin(8), mosi=Pin(11), sck=Pin(10), cs=Pin(9))
flash.write(file)
fpga = ice.fpga(cdone=Pin(26), clock=Pin(24), creset=Pin(27), cram_cs=Pin(9), cram_mosi=Pin(8), cram_sck=Pin(10), frequency=48)
fpga.start()
```

```python
from machine import Pin
import ice
fpga = ice.fpga(cdone=Pin(26), clock=Pin(24), creset=Pin(27), cram_cs=Pin(9), cram_mosi=Pin(8), cram_sck=Pin(10), frequency=48)
fpga.start()
```