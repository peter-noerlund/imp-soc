# Memory map

| Base                      | Description   |
|---------------------------|---------------|
| `0x00000000 - 0x00FFFFFF` | Flash         |
| `0x01000000 - 0x017FFFFF` | RAM A         |
| `0x01800000 - 0x01FFFFFF` | RAM B         |
| `0x02000000 - 0x02000007` | Clock         |
| `0x02000008 - 0x0200000F` | Input         |
| `0x02000010 - 0x02000017` | Audio         |
| `0x02000018 - 0x0200001F` | Video         |

# Audio

Roughtly speaking, PC speakers of the 90'ies worked by letting a counter decrement from a certain point. When it reached zero, the PC speaker output was flipped.
By programming the reset value, a different frequency was obtained.

The DOOM PC speaker format is designed around classical notes, ranging from F3 (174.61Hz) to E7 (2637.02Hz) in 440 Hz tuning with 24 seminotes.

The lowest frequency, 174.61 Hz requires setting the counter to 186,129 on a 65 MHz machine which means we need an 18-bit counter.
