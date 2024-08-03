#include <am.h>
#include <ysyxsoc.h>

void __am_uart_init() {
    return ;
}

void __am_uart_tx(AM_UART_TX_T *uart) {
    return ;
}

void __am_uart_rx(AM_UART_RX_T *uart) {
    if((inb(UART_BASE + UART_LSR) & 0b1) == 1){
        uart->data = inb(UART_BASE);
    }else{
        uart->data = 0xFF;
    }
}
