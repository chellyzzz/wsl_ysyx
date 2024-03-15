/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <memory/host.h>
#include <memory/paddr.h>
// #include <device/mmio.h>
#include <isa.h>

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }
#ifdef CONFIG_MTRACE
typedef struct {
    paddr_t addr;   
    int len;
    paddr_t pc;
    int data;        
    bool is_write;  
} MemoryTrace;

#define MTRACE_SIZE 10
static MemoryTrace memory_traces[MTRACE_SIZE];
static int num_traces = 0;

static inline void mtrace_push(paddr_t addr, int len, int data, bool is_write) {
  #ifdef CONFIG_MTRACE_SIZE_CONF
    if(addr < CONFIG_MTRACE_BASE || addr > CONFIG_MTRACE_BASE + CONFIG_MTRACE_SIZE) return ;
  #endif
  MemoryTrace *trace = &memory_traces[num_traces % MTRACE_SIZE];
  trace->addr = addr;
  trace->len = len;
  trace->data = data;
  trace->pc = cpu.pc;
  trace->is_write = is_write;
  num_traces ++;
}

void print_out_of_bound() {
  int i;
  printf("----------- Memory Trace ------------\n");
  if(num_traces <= MTRACE_SIZE){
    for(i = 0; i < num_traces; i++){
      if(i == num_traces - 1){
        printf("--> pc:"FMT_PADDR" %s: " FMT_PADDR ", Length %d %s:"FMT_WORD"\n", memory_traces[i].pc, memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].len, memory_traces[i].is_write ? "Wdata" : "Rdata", memory_traces[i].data);        
      }
      else printf("    pc:"FMT_PADDR" %s: " FMT_PADDR ", Length %d %s:"FMT_WORD"\n", memory_traces[i].pc,  memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].len, memory_traces[i].is_write ? "Wdata" : "Rdata", memory_traces[i].data);
    }
  }
  else {
    if(num_traces % MTRACE_SIZE == 0){
      for(i = num_traces % MTRACE_SIZE; i < MTRACE_SIZE-1; i++){
        printf("    pc:"FMT_PADDR" %s: " FMT_PADDR ", Length %d %s:"FMT_WORD"\n",  memory_traces[i].pc, memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].len, memory_traces[i].is_write ? "Wdata" : "Rdata", memory_traces[i].data);
      }
        printf("--> pc:"FMT_PADDR" %s: " FMT_PADDR ", Length %d %s:"FMT_WORD"\n",  memory_traces[i].pc, memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].len, memory_traces[i].is_write ? "Wdata" : "Rdata", memory_traces[i].data);

    }
    else{
      for(i = num_traces % MTRACE_SIZE; i < MTRACE_SIZE; i++){
        printf("    pc:"FMT_PADDR" %s: " FMT_PADDR ", Length %d %s:"FMT_WORD"\n",  memory_traces[i].pc, memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].len, memory_traces[i].is_write ? "Wdata" : "Rdata", memory_traces[i].data);
      }

      for(i = 0; i < num_traces % MTRACE_SIZE; i++){
        if(i == num_traces % MTRACE_SIZE - 1){
          printf("--> pc:"FMT_PADDR" %s: " FMT_PADDR ", Length %d %s:"FMT_WORD"\n",  memory_traces[i].pc, memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].len, memory_traces[i].is_write ? "Wdata" : "Rdata", memory_traces[i].data);
        }
        else printf("    pc:"FMT_PADDR" %s: " FMT_PADDR ", Length %d %s:"FMT_WORD"\n",  memory_traces[i].pc, memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].len, memory_traces[i].is_write ? "Wdata" : "Rdata", memory_traces[i].data);
      }
    }
  }
  printf("----------------- End -----------------\n");
}
#endif

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
#ifdef CONFIG_MEM_RANDOM
  uint32_t *p = (uint32_t *)pmem;
  int i;
  for (i = 0; i < (int) (CONFIG_MSIZE / sizeof(p[0])); i ++) {
    p[i] = rand();
  }
#endif
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}

word_t paddr_read(paddr_t addr, int len) {
  word_t data;
  if (likely(in_pmem(addr))) {
    data = pmem_read(addr, len);
    // IFDEF(CONFIG_MTRACE,mtrace_push(addr, len, data, false));
    #ifdef CONFIG_MTRACE
      if(addr != cpu.pc + 4) mtrace_push(addr, len, data, false);
    #endif
    return data;

  }
  // IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  // out_of_bound(addr);
  // return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  IFDEF(CONFIG_MTRACE,mtrace_push(addr, len, data, true));
  if (likely(in_pmem(addr))) {
    pmem_write(addr, len, data); 
    return; 
    }
  // IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  // out_of_bound(addr);
}
