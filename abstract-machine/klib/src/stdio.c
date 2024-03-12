#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define PRESION_NUM 1000

int inttostring(char *dst, int value){
  
    int digits = 0;
    int temp = value;
    while (temp != 0) {
        temp /= 10;
        digits++;
    }

    char tempStr[digits];  
    for (int i = digits - 1; i >= 0; i--) {
        tempStr[i] = '0' + value % 10;
        value /= 10;
    }
    strncpy(dst, tempStr, digits);
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
    char tmp[1000];
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
