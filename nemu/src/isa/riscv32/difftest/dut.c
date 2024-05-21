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
#include <cpu/difftest.h>
#include "../local-include/reg.h"

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  int reg_num = ARRLEN(cpu.gpr);
  for (int i = 0; i < reg_num; i++) {
    if (ref_r->gpr[i] != cpu.gpr[i]) {
       printf("reg error at pc = 0x%08x\n", cpu.pc);
       printf("ref_r->gpr[%d] = 0x%08x, cpu.gpr[%d] = 0x%08x\n", i, ref_r->gpr[i], i, cpu.gpr[i]);  
      return false;
    }
  }
  if(ref_r->pc != cpu.pc){
      printf("pc error at pc = 0x%08x\n", cpu.pc);
      return false;
  }
  if(ref_r->csr.mepc != cpu.csr.mepc){
      printf("mepc error at pc = 0x%08x\n", cpu.pc);
      printf("ref_r->csr.mepc = 0x%08x, cpu.csr.mepc = 0x%08x\n", ref_r->csr.mepc, cpu.csr.mepc);
  }
  if(ref_r->csr.mstatus != cpu.csr.mstatus){
      printf("mstatus error at pc = 0x%08x\n", cpu.pc);
      printf("ref_r->csr.mstatus = 0x%08x, cpu.csr.mstatus = 0x%08x\n", ref_r->csr.mstatus, cpu.csr.mstatus);
      return false;
  }
  // if(ref_r->csr.mcause == 0xb){
  //   // printf("mcasue:%08x error at pc = 0x%08x\n", ref_r->csr.mcause, cpu.pc);
  //   return true;
  // }
  if(ref_r->csr.mcause != cpu.csr.mcause){
      printf("mcause error at pc = 0x%08x\n", cpu.pc);
      printf("ref_r->csr.mcause = 0x%08x, cpu.csr.mcause = 0x%08x\n", ref_r->csr.mcause, cpu.csr.mcause);      
      return false;
  }
  if(ref_r->csr.mtvec != cpu.csr.mtvec){
      printf("mtvec error at pc = 0x%08x\n", cpu.pc);
      printf("ref_r->csr.mtvec = 0x%08x, cpu.csr.mtvec = 0x%08x\n", ref_r->csr.mtvec, cpu.csr.mtvec);
      return false;
  }
  return true;
}

void isa_difftest_attach() {
}
