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
#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2", //7
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void isa_reg_display() {
  for(int i = 0;i < sizeof(regs)/sizeof(regs[0]); i++){
    printf("%-5s\t0x%08x\t%u\n", regs[i], cpu.gpr[i], cpu.gpr[i]);
  }
}
bool diff_checkregs(CPU_state *ref_r, vaddr_t pc) {
  int reg_num = ARRLEN(cpu.gpr);
  for (int i = 0; i < reg_num; i++) {
    if (ref_r->gpr[i] != cpu.gpr[i]) {
       printf("error at pc = 0x%08x, ref[%2d]=0x%08x, dut[%2d]=0x%08x\n", cpu.pc, i, ref_r->gpr[i], i, cpu.gpr[i]);
      return false;
    }
  }
  if(ref_r->pc != cpu.pc){
      printf("error at pc = 0x%08x, ref_pc = 0x%08x\n", cpu.pc, ref_r->pc);
      return false;
  }
  return true;
}

word_t isa_reg_str2val(const char *s, bool *success) {

  for(int i = 0; i < sizeof(regs) / sizeof(regs[0]); i++){
      if(strncmp(s+1, regs[i], strlen(regs[i])) == 0){
        *success =true;
        return cpu.gpr[i];
      }
  }
      *success =false;
      return 0;
}