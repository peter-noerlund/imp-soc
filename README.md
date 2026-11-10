# Memory map

| Base                      | Description   |
|---------------------------|---------------|
| `0x00000000 - 0x00FFFFFF` | Flash         |
| `0x01000000 - 0x017FFFFF` | RAM A         |
| `0x01800000 - 0x01FFFFFF` | ROM           |
| `0x02000000 - 0x02000003` | Timer         |
| `0x02000004 - 0x02000007` | Input         |
| `0x02000008 - 0x0200000B` | Audio         |
| `0x0200000C - 0x0200000F` | Video         |

# Audio

Roughtly speaking, PC speakers of the 90'ies worked by letting a counter decrement from a certain point. When it reached zero, the PC speaker output was flipped.
By programming the reset value, a different frequency was obtained.

The DOOM PC speaker format is designed around classical notes, ranging from F3 (174.61Hz) to E7 (2637.02Hz) in 440 Hz tuning with 24 seminotes.

The lowest frequency, 174.61 Hz requires setting the counter to 186,129 on a 65 MHz machine which means we need an 18-bit counter.

# Routing

QERV (AREA 0):
  floorplan:            46916.25
  cutrows:              46916.25
  tapendcapinsertion:   48821.82
  generatepdn:          48821.82
  globalplacement:      48821.82
  detailedplacement:    52325.18
  cts:                  53983.02
  resizertimingpostcts: 63240.65
  globalrouting:        63240.65
  repairantennas:       63746.14
QERV (AREA 2):
  floorplan:            46472.07
  cutrows:              46472.07
  tapandcapinsertion:   48377.65
  globalplacement:      48377.65
  detailplacement:      51881.01
  cts:                  53676.48
  resizertimingpostcts: 63019.19
  globalrouting:        63019.19
  repairantennas:       63664.81
QERV (AREA 2, vga register):
  floorplan:            46542.14
  detailplacement:      51840.97
  resizertimingpostcts: 63030.45
SERV (AREA 0):
  floorplan:            43589.31
  cutrows:              43589.31
  tapendcapinsertion:   45494.88
  generatepdn:          45494.88
  globalplacement:      45494.88
  detailedplacement:    48737.99
  cts:                  50522.20
  resizertimingpostcts: 60205.24
  globalrouting:        60205.24
  repairantennas:       60778.29
