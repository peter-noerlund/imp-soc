#include <stdint.h>
#include <stdlib.h>

#define VIDEO_BUFFER_ALIGNMENT (64 * 128)

#define DEVICE_TIMER 0
#define DEVICE_INPUT 1
#define DEVICE_AUDIO 2
#define DEVICE_VIDEO 3

#define CSR_MSTATUS 0x300
#define CSR_MIE 0x304
#define CSR_MTVEC 0x305

#define MSTATUS_MIE 0x8

#define MIE_TIMER 0x80

static volatile unsigned int s_timer_counter = 0;

static volatile uint32_t* s_devices = (volatile uint32_t*)0x02000000;

static void arm_timer()
{
    // Setting timer to 325000 will trigger it every 5ms

    s_devices[DEVICE_TIMER] = 325000;
}

void interrupt_handler()
{
    ++s_timer_counter;
    arm_timer();
}

static void fill_screen(uint32_t* screen_buffer, uint32_t value)
{
    for (int i = 0; i != 16 * 96; ++i)
    {
        *screen_buffer++ = value;
    }
}

static void wait_two_frames()
{
    // 60 Hz is 16.67ms
    unsigned int timeout = s_timer_counter + 5;

    arm_timer();

    while (s_timer_counter < timeout);
}

inline void set_csr_flags(uint16_t csr, uint32_t flags)
{
    __asm__ volatile ("csrs %0, %1" : : "i"(csr), "r"(flags));
}

int main()
{
    set_csr_flags(CSR_MIE, MIE_TIMER);
    set_csr_flags(CSR_MSTATUS, MSTATUS_MIE);

    uint32_t* unaligned_screen_buffer = (uint32_t*)malloc(64 * 128 * 2);
    uintptr_t ptr = (uintptr_t)unaligned_screen_buffer;
    if ((ptr % VIDEO_BUFFER_ALIGNMENT) != 0)
    {
        ptr += VIDEO_BUFFER_ALIGNMENT - (ptr % VIDEO_BUFFER_ALIGNMENT);
    }
    uint32_t* screen_buffer = (uint32_t*)ptr;


    // Create all red screen
    fill_screen(screen_buffer, 0x00305555);
    s_devices[DEVICE_VIDEO] = (uint32_t)screen_buffer | 0x80000000;
    wait_two_frames();

    // Create all green screen
    fill_screen(screen_buffer, 0x000C5555);
    wait_two_frames();

    // Create all blue screen
    fill_screen(screen_buffer, 0x00035555);
    wait_two_frames();

    return 0;
}
