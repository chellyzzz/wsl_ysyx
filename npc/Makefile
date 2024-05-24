TOPNAME = top
VNAME = V$(TOPNAME)

BUILD_DIR = $(NPC_HOME)/build
OBJ_DIR = $(BUILD_DIR)/obj_dir
# LOG_DIR = $(NPC_HOME)/logs
# BIN = $(BUILD_DIR)/$(TOPNAME)

$(shell mkdir -p $(BUILD_DIR))

VERILATOR=verilator
# Generate C++ in executable form
VERILATOR_FLAGS += --top-module $(TOPNAME) +incdir+vsrc/include
VERILATOR_FLAGS += -cc --exe --build --trace -MMD \
				-O3 --x-assign fast --x-initial fast
# Warn abount lint issues; may not want this on less solid designs
# VERILATOR_FLAGS += -Wall
VERILATOR_FLAGS += -Wno-fatal
# Generate coverage analysis
# VERILATOR_FLAGS += --coverage

# Add this trace to get a backtrace in gdb
#VERILATOR_FLAGS += --gdbbt

LIBS += $(shell llvm-config --libs)
INC_PATH := $(NPC_HOME)/csrc/include $(NPC_HOME)/csrc/isa/include $(INC_PATH) $(LIBS)
INCFLAGS = $(addprefix -I, $(INC_PATH))
C_FLAGS += -CFLAGS "$(INCFLAGS)"
C_FLAGS += -CFLAGS "-D__GUEST_ISA__=riscv32"

IMAGE ?= $(NEMU_HOME)/am-kernels/tests/cpu-tests/build/dummy-riscv32e-npc.bin

# Read the CONFIG_DIFFTEST definition from autoconf.h
CONFIG_DIFFTEST := $(shell grep -E '^#define CONFIG_DIFFTEST[ \t]+1' $(NPC_HOME)/csrc/include/generated/autoconf.h | awk '{print $$3}')

# Check if CONFIG_DIFFTEST is defined and equals 1
ifeq ($(CONFIG_DIFFTEST), 1)
    NPC_FLAGS += -d $(NEMU_HOME)/build/riscv32-nemu-interpreter-so 
endif

# NPC_FLAGS += -b
NEMUFLAGS += -e $(IMAGE).elf
NPC_FLAGS += -i $(IMAGE)
NPC_FLAGS += -l $(BUILD_DIR)/npc-log.txt

VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

default: run

compile:
	@rm -rf $(OBJ_DIR)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "runing simulation for test module "
	$(VERILATOR) $(C_FLAGS) $(VERILATOR_FLAGS) $(CSRCS) $(VSRCS) \
	--Mdir $(OBJ_DIR) -o $(BUILD_DIR)/$(VNAME) -LDFLAGS "-lLLVM-14 -lreadline -lSDL2"

run: compile
	$(BUILD_DIR)/$(VNAME) $(NPC_FLAGS)

wave:
	gtkwave $(BUILD_DIR)/wave.vcd

menuconfig:
	cd csrc && make menuconfig && cd ..

sim: run wave

clean:
	rm -rf $(BUILD_DIR)

