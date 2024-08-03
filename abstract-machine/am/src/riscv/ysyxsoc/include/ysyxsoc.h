#include <klib-macros.h>
#include <riscv/riscv.h>

#define CSR_MVENDORID 0xF11
#define CSR_MARCHID   0xF12

// CLINT	0x0200_0000~0x0200_ffff
// SRAM	0x0f00_0000~0x0fff_ffff
// UART16550	0x1000_0000~0x1000_0fff
// GPIO	0x1000_2000~0x1000_200f
// PS2	0x1001_1000~0x1001_1007
// VGA	0x2100_0000~0x211f_ffff
// Flash	0x3000_0000~0x3fff_ffff
// PSRAM	0x8000_0000~0x9fff_ffff
// SDRAM	0xa000_0000~0xbfff_ffff
// keyboard 0x1001_1000~0x1001_1007
#define UART_BASE       0x10000000
#define UART_TXFIFO     0x00
#define UART_RXFIFO     0x04
#define UART_DLL        0x00
#define UART_DLH        0x04
#define UART_LCR  3   // Line Control Register
#define UART_LSR  5   // Line Status Register
#define UART_THR  0   // Transmitter Holding Register
#define UART_LSR_EMPTY_MASK 0x20  // Transmitter Holding Register Empty

#define KBD_ADDR        0x10011000
#define SERIAL_PORT     0x10000000
#define RTC_ADDR        0x02000000
#define CLINT_PORT      0x02000000

#define VGACTL_ADDR         0x21000000
#define FB_ADDR             0x21000000