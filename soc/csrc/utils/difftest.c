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

void (*ref_difftest_memcpy)(uint64_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction, vaddr_t skip_addr) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;

static bool is_skip_ref = false;
static int skip_dut_nr_inst = 0;
static bool is_skip_ref_delay = false;
static int skip_nr = 0;
// this is used to let ref skip instructions which
// can not produce consistent behavior with NEMU
void difftest_skip_ref() {
  is_skip_ref = true;
  // If such an instruction is one of the instruction packing in QEMU
  // (see below), we end the process of catching up with QEMU's pc to
  // keep the consistent behavior in our best.
  // Note that this is still not perfect: if the packed instructions
  // already write some memory, and the incoming instruction in NEMU
  // will load that memory, we will encounter false negative. But such
  // situation is infrequent.
  skip_dut_nr_inst = 0;
}

// this is used to deal with instruction packing in QEMU.
// Sometimes letting QEMU step once will execute multiple instructions.
// We should skip checking until NEMU's pc catches up with QEMU's pc.
// The semantic is
//   Let REF run `nr_ref` instructions first.
//   We expect that DUT will catch up with REF within `nr_dut` instructions.
void difftest_skip_dut(int nr_ref, int nr_dut) {
  skip_dut_nr_inst += nr_dut;

  while (nr_ref -- > 0) {
    ref_difftest_exec(1);
  }
}

void init_difftest(char *ref_so_file, long img_size, int port) {
  assert(ref_so_file != NULL);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  ref_difftest_memcpy = (void (*)(uint64_t addr, void *buf, size_t n, bool direction))dlsym(handle , "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (void (*)(void *dut, bool direction, vaddr_t skip_addr))dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (void (*)(uint64_t n))dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (void (*)(uint64_t NO))dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);
  
  void (*ref_difftest_init)(int) = (void (*)(int port))dlsym(handle, "difftest_init");
  assert(ref_difftest_init);
  
  Log("Differential testing: %s", ANSI_FMT("ON", ANSI_FG_GREEN));
  Log("The result of every instruction will be compared with %s. "
      "This will help you a lot for debugging, but also significantly reduce the performance. "
      "If it is not necessary, you can turn it off in menuconfig.", ref_so_file);

  ref_difftest_init(port);
  ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF, 0);
}

static bool checkregs(CPU_state *ref, vaddr_t pc) {
return diff_checkregs(ref, pc);
}

static inline bool in_uart(paddr_t addr) {
  return addr - 0x10000000 < 0x00001000 && addr >= 0x10000000;
}

bool difftest_step(vaddr_t pc, vaddr_t npc){

  // CPU_state ref_r;
  // if(is_skip_ref_delay){
  //   is_skip_ref_delay = false;
  //   ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF, pc);
  //   if (is_skip_ref) {
  //     // to skip the checking of an instruction, just copy the reg state to reference design
  //     is_skip_ref_delay = true; // delay one cycle to skip the instruction
  //     is_skip_ref = false;
  //   }
  //   else ref_difftest_exec(1);
  //   return 1;
  // }

  // ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT, 0);
  // bool reg_eqa = checkregs(&ref_r, pc);

  // if (is_skip_ref) {
  //   // to skip the checking of an instruction, just copy the reg state to reference design
  //   is_skip_ref_delay = true; // delay one cycle to skip the instruction
  //   is_skip_ref = false;
  // }  
  // else ref_difftest_exec(1);

  // return reg_eqa;
  CPU_state ref_r;

  // if(skip_nr > 0){
  //   skip_nr --;
  //   return 1;
  // }

  // if(cpu.pc == 0xa0000010 || cpu.pc == 0xa0000030 || cpu.pc == 0xa0000034){
  //   is_skip_ref = true;
  // }

  // if(is_skip_ref){
  //   ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF, 0);
  //   is_skip_ref = false;
  //   return 1;
  // }
  
  ref_difftest_exec(1);
  ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT, 0);
  bool reg_eqa = checkregs(&ref_r, pc);
  return reg_eqa;
}
#else
void init_difftest(char *ref_so_file, long img_size, int port) {}

#endif