# 指定编译器
CC = gcc

# 编译选项
CFLAGS = -Wall -Wextra -O2

# 目标可执行文件的名称
TARGET = cachesim

# 源文件
SRCS = cachesim.c

# 生成的目标文件
OBJS = $(SRCS:.c=.o)

# 默认目标
all: $(TARGET)

# 编译目标
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

# 生成对象文件
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

run: $(TARGET)
	./$(TARGET) $(NEMU_HOME)/pc_trace.bin

.PHONY: all clean run
