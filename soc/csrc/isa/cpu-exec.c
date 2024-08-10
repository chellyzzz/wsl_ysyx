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
#include "VysyxSoCFull.h"
#include "VysyxSoCFull___024root.h"

#ifdef CONFIG_NVBOARD
#include <nvboard.h>
#endif

// performance counters


CPU_state cpu = {};
uint64_t cycles = 0;
uint64_t ins_cnt = 0;

#define MAX_INST_TO_PRINT 11
#define PC_WAVE_START 0xa0000048
#ifdef CONFIG_WP
bool wp_check();
#endif

static VerilatedContext* contextp;; 
static VysyxSoCFull* top;
static VerilatedVcdC* vcd;
static word_t instr;
extern bool wave_enable;

#define MAX_DEADS 1000
bool dead_detector = true;
int dead_cycles   = 0;

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
  ins_cnt ++;
  // if()
  if(dead_detector){
    if(cpu.pc == top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu1__DOT__pc_next){
      dead_cycles ++;
    }else{
      dead_cycles = 0;
    }
    if(dead_cycles > MAX_DEADS){
      printf("Dead loop detected, pc = " FMT_WORD "\n", cpu.pc);
      exit(1);
    }
  }
  cpu.gpr[0] = 0;
  for(int i = 0; i < 16; i++){
    cpu.gpr[i+1] = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__regfile1__DOT__rf[i] ;
  }
  cpu.csr.mcause = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__Csrs__DOT__mcause;
  cpu.csr.mstatus = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__Csrs__DOT__mstatus;
  cpu.csr.mepc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__Csrs__DOT__mepc;
  cpu.csr.mtvec = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__Csrs__DOT__mtvec;
  cpu.pc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu1__DOT__pc_next;
  #ifdef PC_WAVE_START
  if(cpu.pc == PC_WAVE_START){
    wave_enable = true;
  }
  #endif

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

void verilator_sync_init(VerilatedContext* contextp_sdb, VysyxSoCFull* top_sdb, VerilatedVcdC* vcd_sdb){
  contextp = contextp_sdb;
  top = top_sdb;  
  vcd = vcd_sdb;
}

void decode_pc(Decode* s){
  s->pc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wbu1__DOT__pc;
  s->snpc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wbu1__DOT__pc + 4;
  s->dnpc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ifu1__DOT__pc_next;
  s->isa.inst.val = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__ins;
  instr = s->isa.inst.val;
  #ifdef CONFIG_ITRACE
      disasm_pc(s);
      iringbuf_push(s);
  #endif
  return;
}

void exec_once(Decode *s){
    cycles ++;
    top->reset = 0;
    top->clock = 0;
    top->eval();
    #ifdef CONFIG_WAVE
    if(wave_enable){
      contextp->timeInc(1);
      vcd->dump(contextp->time());
    }
    #endif  
    top->clock = 1;
    top->eval();
    #ifdef CONFIG_NVBOARD
    nvboard_update();
    #endif
    if(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__exu2idu_ready){
      reg_update();
    }
    if(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__exu1__DOT__lsu_post_valid){
      decode_pc(s);
    }
    #ifdef CONFIG_WAVE
    if(wave_enable){
      contextp->timeInc(1);
      vcd->dump(contextp->time());
    }
    #endif
    return;
}

static int trace_and_difftest(Decode *s, vaddr_t dnpc) {
        int flag = 0;
        #ifdef CONFIG_DIFFTEST
        if(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__exu2idu_ready){
          if(!difftest_step(s->pc, s->dnpc)) {
            flag = 1;
          }
        }
        #endif
        #ifdef CONFIG_WP
        if(wp_check()){
          flag = 1;
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
        return flag;
}

void cpu_exec(uint64_t n){
    Decode s;
    int g_print_step = n <= MAX_INST_TO_PRINT && n >= 0 ? n : 0;
    for(; n > 0; n--){
      if(if_end()){
        printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
        Log("npc: %s at pc = " FMT_WORD,
        (hit_goodtrap() ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
          ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED)),
        cpu.pc);       
        printf("\nPerformance counters\n");
        printf("    cycles      : %ld\n", cycles);
        printf("    instrs      : %ld\n", ins_cnt);
        printf("              Fetch per cycles: %ld\n", ifu_delay_end /ins_cnt);
        printf("              Cache hit rates :  %f\n", (float)icache_hits / (float)(icache_hits + icache_miss));
        printf("    Load  instrs: %ld\n", load_cnt);
        printf("              Load  per cycles: %ld\n", load_delay_end /load_cnt);
        printf("    Store instrs: %ld\n", store_cnt);
        printf("              Store per cycles: %ld\n", store_delay_end/store_cnt);
        printf("    Brch  instrs: %ld\n", brch_cnt);
        printf("    Jal   instrs: %ld\n", jal_cnt);
        printf("    csr   instrs: %ld\n", csr_cnt);
        float ipc = (float)ins_cnt / (float)cycles;
        printf("    IPC:          %f\n", ipc); 
        break;
      }
        exec_once(&s);
        #ifdef CONFIG_ITRACE
        if(g_print_step > 0){
          printf("%s\n",s.logbuf);
          g_print_step --;
        }
        #endif
        if(trace_and_difftest(&s, s.dnpc)){
          break;
        }
    }
    return;
}
bool if_end(){
  return instr == 0x100073;
}

int hit_goodtrap(){
  return (cpu.gpr[10] == 0 && instr == 0x100073);
}
