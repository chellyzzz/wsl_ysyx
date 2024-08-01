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
