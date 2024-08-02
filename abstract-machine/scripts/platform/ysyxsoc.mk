AM_SRCS := riscv/ysyxsoc/start.S \
           riscv/ysyxsoc/trm.c \
		   riscv/ysyxsoc/bootloader.c \
           riscv/ysyxsoc/trap.S \
           riscv/ysyxsoc/ioe.c \
           riscv/ysyxsoc/timer.c \
           riscv/ysyxsoc/cte.c \
           riscv/ysyxsoc/input.c \
           platform/dummy/vme.c \
           platform/dummy/mpe.c \
		# #    riscv/ysyxsoc/uart.c \
		#    riscv/ysyxsoc/gpu.c \

CFLAGS    += -fdata-sections -ffunction-sections
LDFLAGS   += -T $(AM_HOME)/scripts/linkersoc.ld \
						 --defsym=_sram_start=0x0f000000 --defsym=_sram_size=0x4000\

LDFLAGS   += --gc-sections -e _start
CFLAGS += -DMAINARGS=\"$(mainargs)\"
CFLAGS += -I$(AM_HOME)/am/src/riscv/ysyxsoc/include

.PHONY: $(AM_HOME)/am/src/riscv/ysyxsoc/trm.c

image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: image
	$(MAKE) -C $(NPC_HOME) run IMAGE=$(IMAGE).bin

sim: image
	$(MAKE) -C $(NPC_HOME) sim IMAGE=$(IMAGE).bin
