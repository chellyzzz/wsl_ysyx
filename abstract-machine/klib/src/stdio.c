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
#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define PRESION_NUM 1000

int uinttostring(char *dst, unsigned int value) {
    if (value == 0) {
        dst[0] = '0';
        dst[1] = '\0';
        return 1;
    }

    int digits = 0;
    unsigned int temp = value;
    while (temp != 0) {
        temp /= 10;
        digits++;
    }

    char tempStr[digits + 1]; // add space for null terminator

    for (int i = digits - 1; i >= 0; i--) { // start from the end
        tempStr[i] = '0' + value % 10;
        value /= 10;
    }
    tempStr[digits] = '\0'; // add null terminator
    strncpy(dst, tempStr, digits + 1);
    return digits;
}

int inttostring(char *dst, int value){
    if (value == 0) {
        dst[0] = '0';
        dst[1] = '\0';
        return 1;
    }

    int isNegative = 0;
    if (value < 0) {
        isNegative = 1;
        value = -value; // convert to positive
    }

    int digits = 0;
    int temp = value;
    while (temp != 0) {
        temp /= 10;
        digits++;
    }

    if (isNegative) {
        digits++; // add space for '-' sign
    }

    char tempStr[digits + 1]; // add space for null terminator
    if (isNegative) {
        tempStr[0] = '-';
    }

    for (int i = digits - 1; i >= isNegative; i--) { // start from the end, skip '-' sign if present
        tempStr[i] = '0' + value % 10;
        value /= 10;
    }
    tempStr[digits] = '\0'; // add null terminator
    strncpy(dst, tempStr, digits + 1);
    return digits;
}

int itohex(char* buf, unsigned int value) {
    char* ptr = buf;
    int cnt = 0;
    for (int i = 28; i >= 0; i -= 4) {
        unsigned int digit = (value >> i) & 0xf;
        if (digit != 0 || cnt != 0) {
            *(ptr++) = (digit < 10) ? ('0' + digit) : ('a' + digit - 10);
            cnt++;
        }
    }
    if (cnt == 0) {
        *(ptr++) = '0';
        cnt = 1;
    }

    *ptr = '\0';
    return cnt;
}

int vsprintf(char *out, const char *fmt, va_list ap) {

    int cnt = 0;

    while (*fmt != '\0') {
    if(*fmt == '%')   {
        fmt++ ;
        if(*fmt < '0' || *fmt > '9') {
        switch (*fmt) {
        case 's':              /* string */
            char *s = va_arg(ap, char *);
            strncpy(out + cnt,s,strlen(s));
            cnt += strlen(s);
            break;
        case 'd':              /* int */
            int d = va_arg(ap, int);
            cnt += inttostring(out + cnt, d);
            break;
        case 'x':              /* hexadecimal */
            unsigned int x = va_arg(ap, unsigned int);
            cnt += itohex(out + cnt, x);
            break;
        case 'u':              /* unsigned int */
            unsigned int u = va_arg(ap, unsigned int);
            cnt += uinttostring(out + cnt, u);  // You need to implement uinttostring function
            break;    
        case 'c':
            char sb_s = (char)va_arg(ap, int);
            *(out + cnt) = sb_s;
            cnt ++;
            break;
        default : cnt = cnt;        
        }
        }else{
        char presion_buff[PRESION_NUM];
        int i_presion = 0 ;
        for(;*fmt >= '0' && *fmt <= '9';fmt++) {
            presion_buff[i_presion++] = *fmt;
        }
        presion_buff[i_presion] = '\0' ;
        int presion = atoi(presion_buff);
        switch (*fmt) {
            case 'd':              /* int */
                int d = va_arg(ap, int);
                char num_string[PRESION_NUM];
                int presion_digits = inttostring(num_string, d);
                for(int presion_temp_num = 0; presion_temp_num < presion - presion_digits; presion_temp_num ++ ) {
                if(presion_buff[0] == '0') {
                    *(out + cnt) = '0';
                }else {
                    *(out + cnt) = ' ';
                }
                cnt++;  
                }
                strncpy(out + cnt, num_string, presion_digits);
                cnt += presion_digits;
                break;
            default : cnt = cnt;       
        }
        }
    }else{
        out[cnt++] = *fmt;
    }
    fmt++;
    }
    out[cnt] = '\0';
    return cnt;
}

int printf(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    char tmp[10000];
    int cnt = vsprintf(tmp, fmt, args);
    putstr(tmp);
    va_end(args);
    return cnt;
}


int sprintf(char *out, const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    int written = vsprintf(out, fmt, args);
    va_end(args);
    return written;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
