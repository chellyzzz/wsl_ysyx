#include <proc.h>
#include <elf.h>
#include <fs.h>
#include <ramdisk.h>

#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
#endif

#if defined(__ISA_AM_NATIVE__)
# define EXPECT_TYPE EM_X86_64
#elif defined(__ISA_RISCV32__) || defined(__ISA_RISCV64__)
# define EXPECT_TYPE EM_RISCV
#else
# error Unsupported ISA
#endif

static uintptr_t loader(PCB *pcb, const char *filename) {
  // TODO();
  int fd = fs_open(filename, 0, 0);
  Elf_Ehdr *ehdr = (Elf_Ehdr*)malloc(sizeof(Elf_Ehdr));
  int ret = fs_read(fd, ehdr, sizeof(Elf_Ehdr));
  assert(ret != -1);
  // ramdisk_read(ehdr, 0, sizeof(Elf_Ehdr));
  assert(*(uint32_t *)(ehdr->e_ident) == 0x464c457f); 
  assert(EXPECT_TYPE == ehdr->e_machine);
  // 遍历程序头表
  for (int i = 0; i < ehdr->e_phnum; i++) {
    Elf_Phdr phdr;
    ramdisk_read(&phdr, ehdr->e_phoff + i * sizeof(Elf_Phdr), sizeof(Elf_Phdr));

    if (phdr.p_type == PT_LOAD) {
      ramdisk_read((void *)phdr.p_vaddr, phdr.p_offset, phdr.p_memsz);

      if (phdr.p_memsz > phdr.p_filesz) {
        memset((void *)(phdr.p_vaddr + phdr.p_filesz), 0, phdr.p_memsz - phdr.p_filesz);
      }
    }
  }

  return ehdr->e_entry;
}
  
void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = 0x%x", entry);
  ((void(*)())entry) ();
}

