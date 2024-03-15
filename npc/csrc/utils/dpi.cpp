#include "verilated_dpi.h"
#include <memory/paddr.h>

extern "C" int if_ebrk(int ins) {
  if(ins == 0x100073) //ebreak;
    return 1;
  else 
    return 0;
}

extern bool rst_n_sync;
extern "C" void check_rst(bool rst_flag){
  if(rst_flag)
    rst_n_sync = true;
  else 
    rst_n_sync = false;
}

extern "C" void npc_pmem_read(int raddr,int *rdata, int ren, int len){
  //raddr = raddr & ~0x3ul;  //clear low 2bit for 4byte align.
  if (ren && raddr>=PMEM_LEFT && raddr<=PMEM_RIGHT){
    *rdata = paddr_read(raddr, len);
  }
  return ;
}

extern "C" void npc_pmem_write(int waddr, int wdata, int wen, int len){
  //waddr = waddr & ~0x3ul;  //clear low 2bit for 4byte align.
  if (wen && len ==4 || len == 2 || len == 1){
    paddr_write(waddr, len, wdata);
  }
  return ;
}
