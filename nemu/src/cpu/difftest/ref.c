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

#include <isa.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>

__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if(direction == DIFFTEST_TO_REF) {
      memcpy(guest_to_host(addr), buf, n);
  } else {
      memcpy(buf, guest_to_host(addr), n);
  } 
}

__EXPORT void difftest_regcpy(void *dut, bool direction, vaddr_t skip_addr) {
  CPU_state *dut_reg = (CPU_state*) dut;
  if(direction == DIFFTEST_TO_REF) {
    for(int i = 0; i < 32; i++){
      cpu.gpr[i] = dut_reg->gpr[i];
    }
    cpu.csr.mtvec = dut_reg->csr.mtvec;
    cpu.csr.mepc = dut_reg->csr.mepc;
    cpu.csr.mstatus = dut_reg->csr.mstatus;
    cpu.csr.mcause = dut_reg->csr.mcause;
    if(skip_addr != 0){
      // printf("regcpy skip target addr: %x at 0x%x\n", skip_addr, cpu.pc);
      cpu.pc = skip_addr;
    }
    else {
      cpu.pc = dut_reg->pc;
    }
  }
  else {
    for(int i = 0; i < 32; i++){
      dut_reg->gpr[i] = cpu.gpr[i];
    }
    dut_reg->pc = cpu.pc;
    dut_reg->csr.mtvec = cpu.csr.mtvec;
    dut_reg->csr.mepc = cpu.csr.mepc;
    dut_reg->csr.mstatus = cpu.csr.mstatus;
    dut_reg->csr.mcause = cpu.csr.mcause;
  }
}

__EXPORT void difftest_exec(uint64_t n) {
  cpu_exec(n);
}

__EXPORT void difftest_raise_intr(word_t NO) {
  assert(0);
}

__EXPORT void difftest_init(int port) {
  void init_mem();
  void init_sram();
  void init_flash();
  void init_sdram();
  void init_uart();

  init_mem();
  init_sram();
  init_flash();
  init_sdram();
  init_uart();
  /* Perform ISA dependent initialization. */
  init_isa();
}
