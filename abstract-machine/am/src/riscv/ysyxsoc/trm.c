#include <am.h>
#include <klib-macros.h>
#include <ysyxsoc.h>

extern char _heap_start, _heap_end;
int main(const char *args);

// extern char _pmem_start;
// #define PMEM_SIZE (128 * 1024 * 1024)
// #define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

# define soc_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))

Area heap = RANGE(&_heap_start, &_heap_end);

#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

#define divider 1
// lsr bit 7 to 1
// divisor latches msb adn lsb
// set lsr bit 7 to 0
// more
void uart_init() {
    outb(UART_BASE + UART_LSR, 0x80);
    outb(UART_BASE + UART_DLH, (uint8_t)(divider >> 8));  // High byte of divisor
    outb(UART_BASE + UART_DLL, (uint8_t)divider);  // Low byte of divisor (115200 baud)
    outb(UART_BASE + UART_LSR, 0x03);  // 8 bits, no parity, one stop bit
}

void putch(char ch) {
  while ((inb(UART_BASE + UART_LSR) & UART_LSR_EMPTY_MASK) == 0);
  outb(UART_BASE, ch);
}

void halt(int code) {
  soc_trap(code);
  while (1);
}

void _trm_init() {
  uart_init();
  // printf_ysyx();
  int ret = main(mainargs);
  halt(ret);
}
