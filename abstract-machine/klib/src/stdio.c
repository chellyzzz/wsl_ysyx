#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define BUF_SIZE 5000

static int int_to_str(char *buf, int value) {
    char temp_buf[12];  
    int is_negative = (value < 0);
    if (is_negative) value = -value;
    
    int i = 0;
    do {
        temp_buf[i++] = '0' + value % 10;
        value /= 10;
    } while (value > 0);

    if (is_negative) {
        temp_buf[i++] = '-';
    }

    int j = 0;
    while (i > 0) {
        buf[j++] = temp_buf[--i];
    }

    buf[j] = '\0';
    return j;
}

static int uint_to_str(char *buf, unsigned int value) {
    char temp_buf[12];
    int i = 0;
    do {
        temp_buf[i++] = '0' + value % 10;
        value /= 10;
    } while (value > 0);

    int j = 0;
    while (i > 0) {
        buf[j++] = temp_buf[--i];
    }

    buf[j] = '\0';
    return j;
}

static int int_to_hex(char *buf, unsigned int value) {
    const char *hex_digits = "0123456789abcdef";
    char temp_buf[9]; // 最多8位十六进制数 + 终止符
    int i = 0;
    
    do {
        temp_buf[i++] = hex_digits[value % 16];
        value /= 16;
    } while (value > 0);

    int j = 0;
    while (i > 0) {
        buf[j++] = temp_buf[--i];
    }

    buf[j] = '\0';
    return j;
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
    size_t cnt = 0;  
    char temp_buf[BUF_SIZE]; 

    while (*fmt != '\0') {
        if (*fmt == '%') {
            fmt++;  // 跳过 '%'
            switch (*fmt) {
                case 's': {  // 处理字符串
                    const char *str = va_arg(ap, const char*);
                    while (*str && cnt < n - 1) {
                        out[cnt++] = *str++;
                    }
                    break;
                }
                case 'd': {  // 处理整数
                    int num = va_arg(ap, int);
                    int len = int_to_str(temp_buf, num);
                    for (int i = 0; i < len && cnt < n - 1; i++) {
                        out[cnt++] = temp_buf[i];
                    }
                    break;
                }
                case 'u': {  // 处理无符号整数
                    unsigned int unum = va_arg(ap, unsigned int);
                    int len = uint_to_str(temp_buf, unum);
                    for (int i = 0; i < len && cnt < n - 1; i++) {
                        out[cnt++] = temp_buf[i];
                    }
                    break;
                }
                case 'p': {  // 处理指针
                    unsigned long ptr = (unsigned long)va_arg(ap, void*);
                    out[cnt++] = '0';
                    out[cnt++] = 'x';
                    int len = int_to_hex(temp_buf, ptr);
                    for (int i = 0; i < len && cnt < n - 1; i++) {
                        out[cnt++] = temp_buf[i];
                    }
                    break;
                }
                case 'x': {  // 处理十六进制
                    unsigned int hex = va_arg(ap, unsigned int);
                    int len = int_to_hex(temp_buf, hex);
                    for (int i = 0; i < len && cnt < n - 1; i++) {
                        out[cnt++] = temp_buf[i];
                    }
                    break;
                }
                case 'c': {  // 处理字符
                    char ch = (char)va_arg(ap, int);
                    if (cnt < n - 1) {
                        out[cnt++] = ch;
                    }
                    break;
                }
                default:  // 其他格式，直接输出字符
                    if (cnt < n - 1) {
                        out[cnt++] = '%';
                    }
                    if (cnt < n - 1) {
                        out[cnt++] = *fmt;
                    }
                    break;
            }
        } else {  // 普通字符，直接复制
            if (cnt < n - 1) {
                out[cnt++] = *fmt;
            }
        }
        fmt++;
    }

    if (cnt < n) {
        out[cnt] = '\0';
    } else if (n > 0) {
        out[n - 1] = '\0';
    }

    return cnt;
}

int sprintf(char *out, const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    int written = vsnprintf(out, BUF_SIZE, fmt, args);  
    va_end(args);
    return written;
}

// 变长参数函数 snprintf
int snprintf(char *out, size_t n, const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    int written = vsnprintf(out, n, fmt, args);  
    va_end(args);
    return written;
}

int printf(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    char temp_buf[BUF_SIZE];
    int written = vsnprintf(temp_buf, BUF_SIZE, fmt, args);
    va_end(args);
    putstr(temp_buf);  
    return written;
}

#endif
