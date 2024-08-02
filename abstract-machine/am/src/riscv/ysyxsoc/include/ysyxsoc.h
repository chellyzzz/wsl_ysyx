#include <klib-macros.h>
#include <riscv/riscv.h>

#define UART_BASE       0x10000000
#define UART_TXFIFO     0x00
#define UART_RXFIFO     0x04
#define UART_DLL        0x00
#define UART_DLH        0x04
#define UART_LSR  5   // Line Status Register
#define UART_THR  0   // Transmitter Holding Register
#define UART_LSR_EMPTY_MASK 0x20  // Transmitter Holding Register Empty


#define KBD_ADDR        (DEVICE_BASE + 0x0000060)
#define RTC_ADDR        (DEVICE_BASE + 0x0000048)
#define VGACTL_ADDR     (DEVICE_BASE + 0x0000100)
#define FB_ADDR         (MMIO_BASE   + 0x1000000)
