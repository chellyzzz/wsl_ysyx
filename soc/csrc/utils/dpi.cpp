#include "verilated_dpi.h"
#include <memory/paddr.h>
#include <cpu/difftest.h>
#include <isa.h>

uint64_t load_cnt = 0;
uint64_t store_cnt = 0;
uint64_t brch_cnt = 0;
uint64_t csr_cnt = 0;
uint64_t jal_cnt = 0;
uint64_t ifu_delay_start = 0;
uint64_t ifu_delay_end = 0;
uint64_t load_delay_start = 0;
uint64_t load_delay_end = 0;
uint64_t store_delay_start = 0;
uint64_t store_delay_end = 0;
uint32_t icache_hits = 0;
uint32_t icache_miss = 0;

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
  ifu_delay_start = cycles;
}

extern "C" void ifu_end(){
  ifu_delay_end += cycles;
  ifu_delay_end -= ifu_delay_start;
}

extern "C" void load_start(){
  load_delay_start = cycles;
}

extern "C" void load_end(){
  load_delay_end += cycles;
  load_delay_end -= load_delay_start;
}

extern "C" void store_start(){
  store_delay_start = cycles;
}

extern "C" void store_end(){
  store_delay_end += cycles;
  store_delay_end -= store_delay_start;
}

extern "C" void cache_hit(){
  icache_hits ++;
}
extern "C" void cache_miss(){
  icache_miss ++;
}