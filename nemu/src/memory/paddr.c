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
#include <device/mmio.h>
#include <isa.h>
#include <cpu/trace.h>

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif

static uint8_t *sram = NULL;
static uint8_t *flash = NULL;
static uint8_t *sdram = NULL;
static uint8_t *uart = NULL;

uint8_t* guest_to_host(paddr_t paddr) { 

  #ifndef CONFIG_TARGET_SHARE
    return pmem + paddr - CONFIG_MBASE; 
  #else
  if (in_pmem(paddr)) {
    return pmem + paddr - CONFIG_MBASE;
  }

  else if(in_sram(paddr)) {
    return sram + paddr - SRAM_BASE;
  }
  else if(in_sdram(paddr)) {
    return sdram + paddr - SDRAM_BASE;
  }
  else if(in_flash(paddr)) {
    return flash + paddr - FLASH_BASE;
  }
  else if(in_uart(paddr)) {
    return uart + paddr - 0x10000000;
  }
  else {
    Log("paddr = " FMT_PADDR" is out of definition", paddr);
    return NULL;
  }
  #endif
}

paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }


static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  if(cpu.pc == 0xa0015f18){
    printf("read sdram data = 0x%x addr 0x%x pc = 0x%x\n", ret, addr, cpu.pc);
  }
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  if(addr >= 0xa2029064 && addr <= 0xa2029068 + 0x4){
    printf("write sdram data = 0x%x addr 0x%x pc = 0x%x\n", data, addr, cpu.pc);
  }
  host_write(guest_to_host(addr), len, data);
}

static void out_of_bound(paddr_t addr) {
  IFDEF(CONFIG_MTRACE, print_out_of_bound());
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_sram() {
  sram = (uint8_t *)malloc(SRAM_SIZE);
  assert(sram);
  memset(sram, 0, SRAM_SIZE);
  Log("sram memory area [" FMT_PADDR ", " FMT_PADDR "]", SRAM_BASE, SRAM_BASE+SRAM_SIZE);
}

void init_sdram() {
  sdram = (uint8_t *)malloc(SDRAM_SIZE);
  assert(sdram);
  memset(sdram, 0, SDRAM_SIZE);
  Log("sram memory area [" FMT_PADDR ", " FMT_PADDR "]", SDRAM_BASE, SDRAM_BASE+SDRAM_SIZE);
}

void init_flash() {
  flash = (uint8_t *)malloc(FLASH_SIZE);
  assert(flash);
  memset(flash, 0, FLASH_SIZE);
  Log("flash memory area [" FMT_PADDR ", " FMT_PADDR "]", FLASH_BASE, FLASH_BASE+FLASH_SIZE);
}

void init_uart() {
  uart = (uint8_t *)malloc(0x00001000);
  assert(uart);
  memset(uart, 0, 0x00001000);
  Log("uart memory area [" FMT_PADDR ", " FMT_PADDR "]", 0x10000000, 0x10000000+0x00001000);
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
  // log_write("paddr_write addr = " FMT_PADDR " len = %d \n", addr, len);
  if(len == 4){
    if(addr % 4 != 0){
      printf("addr = " FMT_PADDR " is not aligned at pc %x\n", addr, cpu.pc);
      assert(0);
    }
  }
  else if(len == 2){
    if(addr % 2 != 0){
      printf("addr = " FMT_PADDR " is not aligned at pc %x\n", addr, cpu.pc);
      assert(0);
    }
  }
  IFDEF(CONFIG_MTRACE, mtrace_push(addr, len, cpu.pc, false, 0));
  word_t data;
  #ifdef CONFIG_TARGET_SHARE
  if (likely(in_flash(addr)||in_sdram(addr)||in_sram(addr)||in_uart(addr))) {
    data = pmem_read(addr, len);
    return data;
  }
  out_of_bound(addr);
  return 0;
  #else
  if (likely(in_pmem(addr))) {
    data = pmem_read(addr, len);
    return data;
  }
  #endif
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  // log_write("paddr_write addr = " FMT_PADDR " len = %d data = " FMT_WORD"\n", addr, len, data);
  if(len == 4){
    if(addr % 4 != 0){
      printf("addr = " FMT_PADDR " is not aligned at pc %x\n", addr, cpu.pc);
      assert(0);
    }
  }
  else if(len == 2){
    if(addr % 2 != 0){
      printf("addr = " FMT_PADDR " is not aligned at pc %x\n", addr, cpu.pc);
      assert(0);
    }
  }
  IFDEF(CONFIG_MTRACE, mtrace_push(addr, len, cpu.pc, true, data));
  #ifdef CONFIG_TARGET_SHARE
  if (in_sdram(addr)||in_sram(addr)) {
    pmem_write(addr, len, data);
    return ;
  }
  else if(in_uart(addr)){
    return ;
  }
  else if(unlikely(in_flash(addr))) {
    printf("write to flash! error!\n");
    assert(0);
    return;
  }
  out_of_bound(addr);

  #else
  if (likely(in_pmem(addr))) {
    pmem_write(addr, len, data); 
    return; 
    }
  #endif
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}
