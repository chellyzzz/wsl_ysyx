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
#include <cpu/trace.h>
#include <cpu/decode.h>
#include "Vtop.h"
#include "Vtop___024root.h"
// #include "verilated.h"
// #include "verilated_vcd_c.h"

CPU_state cpu = {};

#define MAX_INST_TO_PRINT 11

static VerilatedContext* contextp;; 
static Vtop* top;
static VerilatedVcdC* vcd;
static word_t instr;

#ifdef CONFIG_FTRACE

void print_funcnodes();
void free_funcnodes();
const char* get_function_name(vaddr_t addr);
void ftrace_call(Decode *_this, int call_level);
void ftrace_return(Decode *_this, int call_level);
static int last_call_depth = 0;
extern bool ftrace_enable;

#endif

// cpu exec
void reg_update(){
  for(int i = 0; i < 32; i++){
    cpu.gpr[i] = top->rootp->top__DOT__regfile1__DOT__rf[i] ;
  }
  cpu.csr.mcause = top->rootp->top__DOT__Csrs__DOT__mcause;
  cpu.csr.mstatus = top->rootp->top__DOT__Csrs__DOT__mstatus;
  cpu.csr.mepc = top->rootp->top__DOT__Csrs__DOT__mepc;
  cpu.csr.mtvec = top->rootp->top__DOT__Csrs__DOT__mtvec;
  cpu.pc = top->rootp->top__DOT__pc;
  return;
}

void disasm_pc(Decode* s){
  char *p = s->logbuf;
  p += snprintf(p, sizeof(s->logbuf), FMT_WORD ":", s->pc);
  int ilen = 4;
  int i;
  uint8_t *inst = (uint8_t *)&s->isa.inst.val;
  for (i = ilen - 1; i >= 0; i --) {
    p += snprintf(p, 4, " %02x", inst[i]);
  } 
  int ilen_max = MUXDEF(CONFIG_ISA_x86, 8, 4);
  int space_len = ilen_max - ilen;
  if (space_len < 0) space_len = 0;
  space_len = space_len * 3 + 1;
  memset(p, ' ', space_len);
  p += space_len;

  disassemble(p, s->logbuf + sizeof(s->logbuf) - p,
      MUXDEF(CONFIG_ISA_x86, s->snpc, s->pc), (uint8_t *)&s->isa.inst.val, ilen);
}

void verilator_sync_init(VerilatedContext* contextp_sdb, Vtop* top_sdb, VerilatedVcdC* vcd_sdb){
  contextp = contextp_sdb;
  top = top_sdb;  
  vcd = vcd_sdb;
}

void decode_pc(Decode* s){
  s->pc = top->rootp->top__DOT__pc;
  s->snpc = top->rootp->top__DOT__pc + 4;
  s->dnpc = top->rootp->top__DOT__pcu1__DOT__pc_next;
  s->isa.inst.val = top->rootp->top__DOT__ins;
  instr = s->isa.inst.val;
  return;
}

void exec_once(Decode *s){
    top->clk = 0;
    top->eval();
    contextp->timeInc(1);
    vcd->dump(contextp->time());
    top->clk = 1;
    top->eval();
    reg_update();
    decode_pc(s);
    #ifdef CONFIG_ITRACE
        disasm_pc(s);
        iringbuf_push(s);
    #endif
    contextp->timeInc(1);
    vcd->dump(contextp->time());
    return;
}

static void trace_and_difftest(Decode *_this, vaddr_t dnpc) {

        #ifdef CONFIG_DIFFTEST
          if(!difftest_step(s.pc, s.dnpc)) {
            printf("%s\n",s.logbuf);
            iringbuf_print();
            isa_reg_display();
            break;
          }
        #endif
        #ifdef CONFIG_FTRACE
        if(!ftrace_enable){
            return ;
        }
            word_t imm = (_this->isa.inst.val >> 20) & 0xFFF;
            word_t rd = (_this->isa.inst.val >> 7) & 0x1F;
            word_t opt = _this->isa.inst.val & 0x7F;
            word_t rs1 = (_this->isa.inst.val >> 15) & 0x1F;

            if (functab_head) {
                if (opt == 0x6f) {
                if(rd == 1) {
                    ftrace_call(_this, last_call_depth);         
                    last_call_depth++;
                }
                else if(rd == 0){
                    ftrace_return(_this, last_call_depth-1); // j
                    last_call_depth--;
                }
                }
                else if (opt == 0x67) {
                    if(_this->isa.inst.val == 0x00008067) {
                    ftrace_return(_this, last_call_depth-1); // ret -> jalr x0, 0(x1)
                    last_call_depth--;
                    } 
                    else if (rd == 1) {
                        ftrace_call(_this, last_call_depth);
                        last_call_depth++;
                    } 
                    else if (rd == 0 && imm == 0 && rs1 == 1) {
                        ftrace_call(_this, last_call_depth); // jr rs1 -> jalr x0, 0(rs1), which may be other control flow e.g. 'goto','for'
                        last_call_depth++;
                    }
                }
                else if (_this->isa.inst.val == 0x00100073) {
                    ftrace_return(_this, last_call_depth-1); // jal
                    last_call_depth--;
                }
            }
        #endif
}
void cpu_exec(uint64_t n){
    Decode s;
    int g_print_step = n <= MAX_INST_TO_PRINT && n >= 0 ? n : 0;
    if (n == -1) {
        n = -1u;
    }
    for(; n > 0; n--){
      if(contextp->gotFinish()){
        printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
        break;
      }
        exec_once(&s);
        #ifdef CONFIG_ITRACE
        if(g_print_step > 0){
          printf("%s\n",s.logbuf);
          g_print_step --;
        }
        #endif
        trace_and_difftest(&s, s.dnpc);
    }
    return;
}

int hit_goodtrap(){
  return (cpu.gpr[10] == 0 && instr == 0x100073);
}
