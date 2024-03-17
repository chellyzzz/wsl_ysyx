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
  // raddr = raddr & ~0x3u;  //clear low 2bit for 4byte align.
  if (ren && raddr>=PMEM_LEFT && raddr<=PMEM_RIGHT){
    // printf("raddr: 0x%08x, len : %d\n", raddr, len);
    *rdata = paddr_read(raddr, 4);
  }
  return ;
}

extern "C" void npc_pmem_write(int waddr, int wdata, int wen, int len){
  // waddr = waddr & ~0x3u;  //clear low 2bit for 4byte align.
  switch (len)
  {
    case 1:   paddr_write(waddr, 1, wdata); break; // 0000_0001, 1byte.
    case 2:   paddr_write(waddr, 2, wdata); break; // 0000_0011, 2byte.
    case 4:   paddr_write(waddr, 4, wdata); break; // 0000_1111, 4byte.
    default:  break;
  }
  // printf("waddr: 0x%08x\n", waddr);
  return ;
}
