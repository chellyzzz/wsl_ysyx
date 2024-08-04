#include "verilated_dpi.h"
#include <memory/paddr.h>
#include <cpu/difftest.h>
#include <isa.h>

int load_cnt = 0;
int store_cnt = 0;
int brch_cnt = 0;
int csr_cnt = 0;
int jal_cnt = 0;
int ifu_delay_start = 0;
int ifu_delay_end = 0;
int load_delay_start = 0;
int load_delay_end = 0;
int store_delay_start = 0;
int store_delay_end = 0;

extern "C" void load_cnt_dpic(){
  load_cnt ++;
}

extern "C" void csr_cnt_dpic(){
  csr_cnt ++;
}

extern "C" void store_cnt_dpic(){
  store_cnt ++;
}

extern "C" void brch_cnt_dpic(){
  brch_cnt ++;
}

extern "C" void jal_cnt_dpic(){
  jal_cnt ++;
}

extern "C" void ifu_start(){
  ifu_delay_start += cycles;
}

extern "C" void ifu_end(){
  ifu_delay_end += cycles;
}

extern "C" void load_start(){
  load_delay_start += cycles;
}

extern "C" void load_end(){
  load_delay_end += cycles;
}

extern "C" void store_start(){
  store_delay_start += cycles;
}

extern "C" void store_end(){
  store_delay_end += cycles;
}