ifeq ($(ARCH), riscv32e-ysyxSoC)
TOPNAME = ysyxSoCFull
else ifeq ($(ARCH), riscv32e-npc)
TOPNAME = ysyx_23060124
else
TOPNAME = ysyxSoCFull  # 默认值，可以根据你的实际情况设置
endif

NXDC_FILES = constr/top.nxdc

VNAME = V$(TOPNAME)
SOC_HOME := $(abspath $(NEMU_HOME)/../ysyxSoC)

BUILD_DIR = $(NPC_HOME)/build
OBJ_DIR = $(BUILD_DIR)/obj_dir

$(shell mkdir -p $(BUILD_DIR))

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# Verilator
VERILATOR=verilator
# Generate C++ in executable form
VERILATOR_FLAGS += --top-module $(TOPNAME) +incdir+vsrc/include
VERILATOR_FLAGS += +incdir+$(UART16550_DIR) +incdir+$(SPI_DIR)
VERILATOR_FLAGS += --autoflush
VERILATOR_FLAGS += -Wno-style

VERILATOR_FLAGS += --timescale "1ns/1ns" --no-timing
VERILATOR_FLAGS += -cc --exe --build --trace -MMD \
				-O3 --x-assign fast --x-initial fast
# Warn abount lint issues; may not want this on less solid designs
VERILATOR_FLAGS += -Wno-fatal
# Accelerate speed
VERILATOR_FLAGS += -j 8


LIBS += $(shell llvm-config --libs)
INC_PATH += $(NPC_HOME)/csrc/include $(NPC_HOME)/csrc/isa/include $(LIBS)
INC_PATH += $(shell sdl2-config --cflags | sed 's/-I//g')

UART16550_DIR := $(SOC_HOME)/perip/uart16550/rtl
SPI_DIR := $(SOC_HOME)/perip/spi/rtl

C_FLAGS += -CFLAGS "$(INCFLAGS)"
C_FLAGS += -CFLAGS "-D__GUEST_ISA__=riscv32"

# Read the CONFIG_DIFFTEST definition from autoconf.h
CONFIG_DIFFTEST := $(shell grep -E '^#define CONFIG_DIFFTEST[ \t]+1' $(NPC_HOME)/csrc/include/generated/autoconf.h | awk '{print $$3}')

# Check if CONFIG_DIFFTEST is defined and equals 1
ifeq ($(CONFIG_DIFFTEST), 1)
    NPC_FLAGS += -d $(NEMU_HOME)/build/riscv32-nemu-interpreter-so 
endif

# NPC_FLAGS += $(ARGS)
NPC_FLAGS += --log=$(BUILD_DIR)/npc-log.txt
NPC_FLAGS += -b
NPC_FLAGS += -i $(IMAGE)

VSRCS += $(shell find $(abspath $(NPC_HOME)/vsrc) -name "*.v" -print)
VSRCS += $(shell find $(SOC_HOME)/perip -name "*.v" -print)
VSRCS += $(shell find $(SOC_HOME)/build -name "*.v" -print)
CSRCS += $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)

LDFLAGS += -lLLVM-14 -lreadline 
LDFLAGS += -lSDL2 -lSDL2_image

INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

default: run

compile: $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(VERILATOR) $(C_FLAGS) $(VERILATOR_FLAGS) \
	--top-module $(TOPNAME) $^ \
	$(addprefix -CFLAGS , $(CXXFLAGS)) \
	--Mdir $(OBJ_DIR) --exe -o $(BUILD_DIR)/$(VNAME) \
	$(addprefix -LDFLAGS , $(LDFLAGS))\

run: compile
	$(BUILD_DIR)/$(VNAME) $(NPC_FLAGS)

wave:
	gtkwave $(BUILD_DIR)/wave.vcd

menuconfig:
	cd csrc && make menuconfig && cd ..

sim: run wave

clean:
	rm -rf $(BUILD_DIR)

.PHONY: default menuconfig clean run

