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
#include <cpu/trace.h>

#define MSTATUS_MPP_MASK     (0x3 << 11)  
#define MSTATUS_MPIE         (1 << 7)   
#define MSTATUS_MIE          (1 << 3)

word_t isa_raise_intr(word_t NO, vaddr_t epc) {
  /* TODO: Trigger an interrupt/exception with ``NO''.
   * Then return the address of the interrupt/exception vector.
   */
  //set mpie = mie
  //set mpp = M mode
  //set mie = 0
  int mie = cpu.csr.mstatus & MSTATUS_MIE;
  cpu.csr.mstatus = (cpu.csr.mstatus | MSTATUS_MPIE) & (mie << 4); 
  cpu.csr.mstatus = (cpu.csr.mstatus & ~ MSTATUS_MPP_MASK) | MSTATUS_MPP_MASK;
  cpu.csr.mstatus = (cpu.csr.mstatus & ~ MSTATUS_MIE); 

  cpu.csr.mepc = epc;
  cpu.csr.mcause = NO;

  #ifdef CONFIG_ETRACE
    etrace_print(NO, epc, cpu.csr.mtvec, cpu.csr.mstatus);
  #endif
  return cpu.csr.mtvec;
}

word_t isa_query_intr() {
  return INTR_EMPTY;
}
