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
static uint8_t *mrom = NULL;
static uint8_t *flash = NULL;
static uint8_t *psram = NULL;
#define ROWS 8192
#define COLS 512
#define BANKS 4

static uint16_t sdram[BANKS][ROWS][COLS];

uint8_t* guest_to_host(paddr_t paddr) { 
  if (in_pmem(paddr)) {
    return pmem + paddr - CONFIG_MBASE;
  }
  else if(in_mrom(paddr)) {
    return mrom + paddr - MROM_BASE;
  }
  else if(in_sram(paddr)) {
    return sram + paddr - SRAM_BASE;
  }
  else if(in_flash(paddr)){
    return flash + paddr - FLASH_BASE;
  }
  else if(in_psram(paddr)){
    return psram + paddr - PSRAM_BASE;
  }
  else {
    Log("paddr = " FMT_PADDR" is out of definition", paddr);
    return NULL;
  }
}
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static void out_of_bound(paddr_t addr) {
  IFDEF(CONFIG_MTRACE, print_out_of_bound());
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}


static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

extern "C" void mrom_read(int32_t addr, int32_t *data) {
    word_t ret = host_read(guest_to_host(addr), 4);
    *data = ret;
}

extern "C" void flash_read(int32_t addr, int32_t *data) { 
	  int align_addr = addr + FLASH_BASE;
    word_t ret = host_read(guest_to_host(align_addr), 4);
    *data = ret;
}

#define PSRAM_TEST 0x8ff0ffff
extern "C" void psram_read(int32_t raddr, int32_t *rdata) { 
	  int align_addr = raddr + PSRAM_BASE;
    word_t ret = host_read(guest_to_host(align_addr), 4);
    *rdata = ret;
    if(align_addr >= PSRAM_TEST && align_addr <= PSRAM_TEST + 4) printf("psram_read: raddr = %x, rdata = %x\n", raddr, *rdata);
}

extern "C" void psram_write(int32_t waddr, int32_t wdata, int32_t wmask) {
    int align_addr = waddr + PSRAM_BASE;
    if(align_addr >= PSRAM_TEST && align_addr <= PSRAM_TEST + 4) printf("psram_write: waddr = %x, wdata = %x, wmask = %x\n", waddr, wdata, wmask/2);
    host_write(guest_to_host(align_addr), wmask/2, wdata);
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

void init_mrom() {
  mrom = (uint8_t *)malloc(MROM_SIZE);
  assert(mrom);
  Log("mrom memory area [" FMT_PADDR ", " FMT_PADDR "]", MROM_BASE, MROM_BASE + MROM_SIZE);
}

void init_flash() {
  flash = (uint8_t *)malloc(FLASH_SIZE);
  assert(flash);
  Log("flash memory area [" FMT_PADDR ", " FMT_PADDR "]", FLASH_BASE, FLASH_BASE + FLASH_SIZE);
}

void init_sram() {
  sram = (uint8_t *)malloc(SRAM_SIZE);
  assert(sram);
  Log("sram memory area [" FMT_PADDR ", " FMT_PADDR "]", SRAM_BASE, SRAM_BASE + SRAM_SIZE);
}

// void init_sdram() {
//   sdram = (uint8_t *)malloc(SDRAM_SIZE);
//   assert(sdram);
//   Log("sdram memory area [" FMT_PADDR ", " FMT_PADDR "]", SDRAM_BASE, SDRAM_BASE + SDRAM_SIZE);
// }


void init_psram() {
  psram = (uint8_t *)malloc(PSRAM_SIZE);
  assert(psram);
  Log("psram memory area [" FMT_PADDR ", " FMT_PADDR "]", PSRAM_BASE, PSRAM_BASE + PSRAM_SIZE);
}

word_t paddr_read(paddr_t addr, int len) {
  word_t data;
  if (likely(in_pmem(addr))) {
    data = pmem_read(addr, len);

    #ifdef CONFIG_MTRACE
      if(addr != cpu.pc + 4) mtrace_push(addr, len, cpu.pc, false, data);
    #endif
    return data;

  }
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  IFDEF(CONFIG_MTRACE, mtrace_push(addr, len, cpu.pc, true, data));
  if (likely(in_pmem(addr))) {
    pmem_write(addr, len, data); 
    return; 
    }
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data);return);
  out_of_bound(addr);
}
