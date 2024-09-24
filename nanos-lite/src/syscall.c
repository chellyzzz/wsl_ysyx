#include <common.h>
#include "syscall.h"
#include <fs.h>
// #define STRACE

void sys_yield(Context *c);
void sys_exit(Context *c);
void sys_write(Context *c);
void sys_brk(Context *c);
void sys_open(Context *c);
void sys_lseek(Context *c);
void sys_close(Context *c);
void sys_read(Context *c);

#ifdef STRACE
void get_syscall_name(int id);
#endif

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;

  #ifdef STRACE
  printf("syscall trace ID = %d\n", a[0]);
  get_syscall_name(a[0]);
  #endif

  switch (a[0]) {
    case SYS_yield: sys_yield(c); break;
    case SYS_exit:  sys_exit(c); break;
    case SYS_write: sys_write(c); break;
    case SYS_brk:   sys_brk(c); break;
    case SYS_open:  sys_open(c); break;
    case SYS_lseek: sys_lseek(c); break;
    case SYS_close: sys_close(c); break;
    case SYS_read:  sys_read(c); break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }

}

void sys_yield(Context *c) {
  yield(); 
  c->GPRx = 0;
}

void sys_write(Context *c) {
  // int fd = c->GPR2;
  // char *buf = (char *)c->GPR3;
  // size_t count = c->GPR4;
  // if (fd == 1 || fd == 2) {
  //   for (size_t i = 0; i < count; i++) {
  //     putch(buf[i]);
  //   }
  //   c->GPRx = count;
  // } else {
  //   c->GPRx = -1;
  // }
  c->GPRx = fs_write(c->GPR2, (void *)c->GPR3, c->GPR4);
}

void sys_brk(Context *c) {
  c->GPRx = 0;
}

void sys_exit(Context *c) {
  halt(c->GPRx);
}

void sys_open(Context *c) {
  c->GPRx = fs_open((char *)c->GPR2, c->GPR3, c->GPR4);
}

void sys_read(Context *c) {
  c->GPRx = fs_read(c->GPR2, (void *)c->GPR3, c->GPR4);
}

void sys_close(Context *c) {
  c->GPRx = fs_close(c->GPR2);
} 

void sys_lseek(Context *c) {
  c->GPRx = fs_lseek(c->GPR2, c->GPR3, c->GPR4);
}

#ifdef STRACE
void get_syscall_name(int id){
  switch (id) {
    case SYS_exit: printf("SYS_exit\n"); break;
    case SYS_yield: printf("SYS_yield\n"); break;
    case SYS_open: printf("SYS_open\n"); break;
    case SYS_read: printf("SYS_read\n"); break;
    case SYS_write: printf("SYS_write\n"); break;
    case SYS_kill: printf("SYS_kill\n"); break;
    case SYS_getpid: printf("SYS_getpid\n"); break;
    case SYS_close: printf("SYS_close\n"); break;
    case SYS_lseek: printf("SYS_lseek\n"); break;
    case SYS_brk: printf("SYS_brk\n"); break;
    case SYS_fstat: printf("SYS_fstat\n"); break;
    case SYS_time: printf("SYS_time\n"); break;
    case SYS_signal: printf("SYS_signal\n"); break;
    case SYS_execve: printf("SYS_execve\n"); break;
    case SYS_fork: printf("SYS_fork\n"); break;
    case SYS_link: printf("SYS_link\n"); break;
    case SYS_unlink: printf("SYS_unlink\n"); break;
    case SYS_wait: printf("SYS_wait\n"); break;
    case SYS_times: printf("SYS_times\n"); break;
    case SYS_gettimeofday: printf("SYS_gettimeofday\n"); break;
    default: panic("Unhandled syscall ID = %d", id);
  }
}
#endif