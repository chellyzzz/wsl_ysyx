#include <common.h>
#include <memory/paddr.h>
#include <dlfcn.h>
#include <difftest-def.h>
#include <isa.h>
#include <cpu/cpu.h>
#include <utils.h>

#ifdef CONFIG_DIFFTEST

extern uint32_t *dut_reg;
extern uint32_t dut_pc;

typedef void (*DifftestMemcpyFunc)(uint64_t addr, void *buf, size_t n, bool direction);
typedef void (*DifftestRegcpyFunc)(void *dut, bool direction);
typedef void (*DifftestExecFunc)(uint64_t n);
typedef void (*DifftestRaiseIntrFunc)(uint64_t NO);
typedef void (*DifftestInitFunc)(int);

DifftestMemcpyFunc ref_difftest_memcpy = NULL;
DifftestRegcpyFunc ref_difftest_regcpy = NULL;
DifftestExecFunc ref_difftest_exec = NULL;
DifftestRaiseIntrFunc ref_difftest_raise_intr = NULL;
DifftestInitFunc ref_difftest_init = NULL;

void init_difftest(char *ref_so_file, long img_size, int port) {
  assert(ref_so_file != NULL);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);
  ref_difftest_memcpy = (DifftestMemcpyFunc)dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (DifftestRegcpyFunc)dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (DifftestExecFunc)dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (DifftestRaiseIntrFunc)dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  ref_difftest_init = (DifftestInitFunc)dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  Log("Differential testing: %s", ANSI_FMT("ON", ANSI_FG_GREEN));
  Log("The result of every instruction will be compared with %s. "
      "This will help you a lot for debugging, but also significantly reduce the performance. "
      "If it is not necessary, you can turn it off in menuconfig.", ref_so_file);

  ref_difftest_init(port);
  ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

static bool checkregs(CPU_state *ref, vaddr_t pc) {
  return diff_checkregs(ref, pc);
}


bool difftest_step(vaddr_t pc, vaddr_t npc){

  CPU_state ref_r;
  ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);

  bool reg_eqa = checkregs(&ref_r, pc);
  ref_difftest_exec(1);
  return reg_eqa;
}
#else
void init_difftest(char *ref_so_file, long img_size, int port) {}

#endif