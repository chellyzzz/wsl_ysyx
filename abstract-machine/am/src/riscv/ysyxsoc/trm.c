#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <ysyxsoc.h>

extern char _heap_start, _heap_end;
int main(const char *args);

#define PMEM_SIZE 4096
#define PMEM_END  ((uintptr_t)&_heap_start + PMEM_SIZE)

# define soc_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))

Area heap = RANGE(&_heap_start, &_heap_end);

#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

#define divider 1

void uart_init() {

    outb(UART_BASE + UART_LCR, 0x80);
    outb(UART_BASE + UART_DLH, (uint8_t)(divider >> 8));  // High byte of divisor
    outb(UART_BASE + UART_DLL, (uint8_t)divider);  // Low byte of divisor (115200 baud)
    outb(UART_BASE + UART_LCR, 0x03);  // 8 bits, no parity, one stop bit
    // outb(UART_BASE + 2, 0x01); // FCR寄存器，
    // outb(UART_BASE + 1, 0x01); // 使能接收中断
    
    //TODO: set lsr bit 7 to 0
    //     // Step 4: Enable and configure FIFOs
    // outb(UART_BASE + UART_FCR, 0xC7);

    // // Step 5: Configure modem control register
    // outb(UART_BASE + UART_MCR, 0x0B);

}

void putch(char ch) {
  while ((inb(UART_BASE + UART_LSR) & UART_LSR_EMPTY_MASK) == 0);
  outb(UART_BASE, ch);
}

void halt(int code) {
  soc_trap(code);
  while (1);
}


static inline uint32_t read_csr(uint32_t csr) {
  uint32_t value;
  asm volatile ("csrr %0, %1" : "=r"(value) : "i"(csr));
  return value;
}

void printf_ysyx() {
  uint32_t mvendorid = read_csr(CSR_MVENDORID);
  uint32_t marchid = read_csr(CSR_MARCHID);
  printf("%c%c%c%c ID : %x\n", (mvendorid >> 24) & 0xFF, (mvendorid >> 16) & 0xFF, (mvendorid >> 8) & 0xFF, mvendorid & 0xFF, marchid);
}

void _trm_init() {
  uart_init();
  // printf_ysyx();
  int ret = main(mainargs);
  halt(ret);
}
