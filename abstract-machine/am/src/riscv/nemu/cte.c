#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  // printf("c gpr[0] = %d\n", c->gpr[0]);
  if (user_handler) {
    Event ev = {0};
    // if(c->mcause == -1) printf("c->mcause = %d\n", c->mcause);
    switch (c->mcause) {
      case 11: ev.event = EVENT_YIELD; break;
      default: ev.event = EVENT_ERROR; break;
    }
    c = user_handler(ev, c);
    assert(c != NULL);
  }
  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

  // register event handler
  user_handler = handler;

  return true;
}

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  Context *kctx = (Context *)(kstack.end - sizeof(Context));
  kctx->mstatus = 0x00001800;
  kctx->mepc=(uintptr_t) entry;
  kctx->gpr[10]=(uintptr_t) arg;
  return kctx;
}

void yield() {

#ifdef __riscv_e
  asm volatile("li a5, -1; ecall");
#else

  // asm volatile("li a7, -1; ecall");
  asm volatile("li a7, 0xb; ecall");

#endif
}

bool ienabled() {
  return false;
}

void iset(bool enable) {
}
