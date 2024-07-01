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

#include <cpu/cpu.h>
#include <isa.h>
#include <elf.h>
#include <cpu/trace.h>
#include <cpu/cpu.h>
#include <cpu/decode.h>

#ifdef CONFIG_ITRACE

static RingBuff_Type iringbuf[RingBuffSize];
static int ptr = 0;

int iringbuf_push(Decode *s) {
  strcpy(iringbuf[ptr % RingBuffSize].logbuf, s->logbuf);
  ptr ++;
  return ptr;
}

void iringbuf_print() {
  int i;
  printf("---------- Instruction Trace ----------\n");
  if(ptr <= RingBuffSize){
    for(i = 0; i < ptr; i++){
      if(i == ptr - 1){
        printf("--> %s\n", iringbuf[i].logbuf);        
      }
      else printf("    %s\n", iringbuf[i].logbuf);
    }
  }
  else {
    if(ptr % RingBuffSize == 0){
      for(i = ptr % RingBuffSize; i < RingBuffSize-1; i++){
        printf("    %s\n", iringbuf[i].logbuf);
      }
        printf("--> %s\n", iringbuf[i].logbuf);
    }
    else{
      for(i = ptr % RingBuffSize; i < RingBuffSize; i++){
        printf("    %s\n", iringbuf[i].logbuf);
      }
      for(i = 0; i < ptr % RingBuffSize; i++){
        if(i == (ptr % RingBuffSize) - 1){
          printf("--> %s\n", iringbuf[i].logbuf);
        }
        else printf("    %s\n", iringbuf[i].logbuf);
      }
    }
  }
  
  printf("----------------- End -----------------\n");
}
#endif

#ifdef CONFIG_FTRACE
size_t num_functions;
functab_node* functab_head = NULL;

size_t safe_fread(void *ptr, size_t size, size_t nmemb, FILE *stream) {
    size_t read_count = fread(ptr, size, nmemb, stream);
    if (read_count != nmemb) {
        printf("Failed to read data from file.\n");
        exit(EXIT_FAILURE);
    }
    return read_count;
}

void parse_elf(const char *elf_dst){
	    // 打开 ELF 文件
    FILE* elf_file = fopen(elf_dst, "rb");
    if (!elf_file) {
        printf("Failed to open ELF file.\n");
        return;
    }
	Log("specified ELF file: %s", elf_dst);

    // 解析 ELF 文件头部
    Elf32_Ehdr elf_header;
	safe_fread(&elf_header, sizeof(Elf32_Ehdr), 1, elf_file);	
	
    // 定位到符号表节区
    Elf32_Shdr symtab_header;
    fseek(elf_file, elf_header.e_shoff, SEEK_SET);
    for (int i = 0; i < elf_header.e_shnum; i++) {
        Elf32_Shdr section_header;
		safe_fread(&section_header, sizeof(Elf32_Shdr), 1, elf_file);
        if (section_header.sh_type == SHT_SYMTAB) {
            symtab_header = section_header;
            break;
        }
    }

    // 读取字符串表节区
    Elf32_Shdr strtab_header;
    fseek(elf_file, elf_header.e_shoff + elf_header.e_shentsize * symtab_header.sh_link, SEEK_SET);
    safe_fread(&strtab_header, sizeof(Elf32_Shdr), 1, elf_file);
    char* strtab = malloc(strtab_header.sh_size);
    fseek(elf_file, strtab_header.sh_offset, SEEK_SET);
    safe_fread(strtab, strtab_header.sh_size, 1, elf_file);

    // 统计函数数量
    fseek(elf_file, symtab_header.sh_offset, SEEK_SET);
    for (int i = 0; i < symtab_header.sh_size / sizeof(Elf32_Sym); i++) {
        Elf32_Sym symbol;
        safe_fread(&symbol, sizeof(Elf32_Sym), 1, elf_file);
        if (ELF32_ST_TYPE(symbol.st_info) == STT_FUNC) {
            num_functions++;
        }
    }

    // 读取符号表并存储函数信息
    functab_head = malloc(num_functions * sizeof(functab_node));
    size_t function_count = 0;

    fseek(elf_file, symtab_header.sh_offset, SEEK_SET);
    for (int i = 0; i < symtab_header.sh_size / sizeof(Elf32_Sym); i++) {
        Elf32_Sym symbol;
        safe_fread(&symbol, sizeof(Elf32_Sym), 1, elf_file);

        if (ELF32_ST_TYPE(symbol.st_info) == STT_FUNC) {
            (functab_head)[function_count].name = strdup(&strtab[symbol.st_name]);
            (functab_head)[function_count].addr = symbol.st_value;
            (functab_head)[function_count].addr_end = symbol.st_value + symbol.st_size;
            function_count++;
        }
    }


    fclose(elf_file);
    free(strtab);
}
void print_funcnodes(){
    printf("Found %zu functions:\n", num_functions);
    for (size_t i = 0; i < num_functions; ++i) {
        printf("Function %zu: %s, Address: 0x%x - 0x%x\n", i, functab_head[i].name, functab_head[i].addr, functab_head[i].addr_end);
    }
}

void free_funcnodes(){
	for (size_t i = 0; i < num_functions; ++i) {
        free(functab_head[i].name);
    }
    free(functab_head);
}

const char* get_function_name(vaddr_t addr) {
    for (size_t i = 0; i < num_functions; ++i) {
        if (functab_head[i].addr <= addr && addr < functab_head[i].addr_end) {
            return functab_head[i].name;
        }
    }
    return "???"; // 如果未找到对应函数，则返回 "???"
}
#define CALL_LEVEL_LIMIT 0
void ftrace_call(Decode *_this, int call_level) {
    if(call_level < CALL_LEVEL_LIMIT) return;
    const char* func_name = get_function_name(_this->dnpc);
    printf("0x%08x: ", _this->pc);
    for (int i = 0; i < call_level-CALL_LEVEL_LIMIT; ++i) {
        printf("  ");
    }
    printf("call [%s@0x%x]\n", func_name, _this->dnpc);}

// 函数返回跟踪
void ftrace_return(Decode *_this, int call_level) {
    if(call_level < CALL_LEVEL_LIMIT) return;
    const char* func_name = get_function_name(_this->pc);
    printf("0x%08x: ", _this->pc);
    for (int i = 0; i < call_level-CALL_LEVEL_LIMIT; ++i) {
        printf("  ");
    }
    printf("ret  [%s]\n", func_name);
}

#endif

#ifdef CONFIG_DTRACE
#include <device/map.h>

void dtrace_read(paddr_t addr, int len, IOMap *map) {
  printf("dtrace_read: %8s at %08x, len = %d\n", map->name, addr, len);
}

void dtrace_write(paddr_t addr, int len, word_t data, IOMap *map) {
  printf("dtrace_write: %8s at %08x, data[len] = %08x [%d] \n", map->name, addr, data, len);
}

#endif

#ifdef CONFIG_ETRACE
void etrace_print(word_t NO, vaddr_t epc, vaddr_t mtvec, word_t mstatus) {
  printf("\nRaise interrupt mcause  = %d at pc = "FMT_PADDR"\t", NO, epc);
  printf("mtvec = "FMT_WORD", mstatus = "FMT_WORD"\n", mtvec, mstatus);  
} 
#endif


#ifdef CONFIG_MTRACE
typedef struct {
    paddr_t addr;
    paddr_t pc;
    int wdata;   
    int len;        
    bool is_write;  
} MemoryTrace;

#define MTRACE_SIZE 10
static MemoryTrace memory_traces[MTRACE_SIZE];
static int num_traces = 0;

void mtrace_push(paddr_t addr, int len, paddr_t pc, bool is_write, word_t wdata) {
  #ifdef CONFIG_MTRACE_SIZE_CONF
    if(addr < CONFIG_MTRACE_BASE || addr > CONFIG_MTRACE_BASE + CONFIG_MTRACE_SIZE) return ;
  #endif
  MemoryTrace *trace = &memory_traces[num_traces % MTRACE_SIZE];
  trace->addr = addr;
  trace->len = len;
  trace->is_write = is_write;
  trace->pc = pc;
  trace->wdata = wdata;
  num_traces ++;
}

void print_out_of_bound() {
  int i;
  printf("----------- Memory Trace ------------\n");
  if(num_traces <= MTRACE_SIZE){
    for(i = 0; i < num_traces; i++){
      if(i == num_traces - 1){
        printf("--> %s: " FMT_PADDR ", data = "FMT_WORD" Length %d at 0x%x\n", memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].wdata, memory_traces[i].len, memory_traces[i].pc);        
      }
      else printf("    %s: " FMT_PADDR ", data = "FMT_WORD" Length %d at 0x%x\n", memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].wdata, memory_traces[i].len, memory_traces[i].pc);
    }
  }
  else {
    if(num_traces % MTRACE_SIZE == 0){
      for(i = num_traces % MTRACE_SIZE; i < MTRACE_SIZE-1; i++){
        printf("    %s: " FMT_PADDR ", data = "FMT_WORD" Length %d at 0x%x\n", memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].wdata, memory_traces[i].len, memory_traces[i].pc);
      }
        printf("--> %s: " FMT_PADDR ", data = "FMT_WORD" Length %d at 0x%x\n", memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].wdata, memory_traces[i].len, memory_traces[i].pc);

    }
    else{
      for(i = num_traces % MTRACE_SIZE; i < MTRACE_SIZE; i++){
        printf("    %s: " FMT_PADDR ", data = "FMT_WORD" Length %d at 0x%x\n", memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].wdata, memory_traces[i].len, memory_traces[i].pc);
      }

      for(i = 0; i < num_traces % MTRACE_SIZE; i++){
        if(i == num_traces % MTRACE_SIZE - 1){
          printf("--> %s: " FMT_PADDR ", data = "FMT_WORD" Length %d at 0x%x\n", memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].wdata, memory_traces[i].len, memory_traces[i].pc);
        }
        else printf("    %s: " FMT_PADDR ", data = "FMT_WORD" Length %d at 0x%x\n", memory_traces[i].is_write ? "Waddr" : "Raddr", memory_traces[i].addr, memory_traces[i].wdata, memory_traces[i].len, memory_traces[i].pc);
      }
    }
  }
  printf("----------------- End -----------------\n");
}
#endif