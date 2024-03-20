#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  assert(s != NULL);
  size_t cnt = 0;
  while (*s != '\0')
  {
    cnt++;
    s++;
  }
  return cnt;
}

char *strcpy(char *dst, const char *src) {
  assert(src != NULL && dst != NULL);
  char *tmp = dst;
  while (*src != '\0')
  {
    *(dst++) = *(src++);
  }
  *dst = '\0';
  return tmp;
}

char *strncpy(char *dst, const char *src, size_t n) {
  assert(src != NULL && dst != NULL);
  char *tmp = dst;
  while (*src != '\0' && n > 0)
  {
    *(dst++) = *(src++);
    n--;
  }
  while (n > 0)
  {
    *(dst++) = '\0';
    n--;
  }

  return tmp;
}

char *strcat(char *dst, const char *src) {
  assert(src != NULL && dst != NULL);
  strcpy(dst + strlen(src), src);
  return dst;
}

int strcmp(const char *s1, const char *s2) {
  // assert(s1 != NULL && s2 != NULL);
  if (s1 == NULL && s2 == NULL) {
    return 0;
  }
  else if (s1 == NULL) {
    return -1;
  }
  else if (s2 == NULL) {
    printf("s2 is NULL\n");
    return 1;
  }
  while (*s1 != '\0' && *s2 != '\0')
  {
    if (*s1 != *s2) {
        return (*s1 - *s2);
    }
    s1++;
    s2++;
  }
  if(*s1 != '\0' && *s2 != '\0'){
    int n1 = *s1 != '\0'? *s1 : 0;
    int n2 = *s2 != '\0'? *s2 : 0;
    return n1 - n2;
  }

  return 0;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  assert(s1 != NULL && s2 != NULL);
  while (n > 0 && *s1 != '\0' && *s2 != '\0') {
    if (*s1 != *s2) {
        return (*s1 - *s2);
    }
    s1++;
    s2++;
    n--;
  }
  if (n > 0) {
    return (*s1 - *s2);
  }
  return 0;
}

void *memset(void *s, int c, size_t n) {
    unsigned char *tmp = s;
    while (n-- > 0) {
        *(tmp++) = (unsigned char) c;
    }
    return s;
}

void *memmove(void *dst, const void *src, size_t n) {
    assert(dst != NULL && src != NULL);

    unsigned char *d = dst;
    const unsigned char *s = src;

    if (d < s) {
        while (n-- > 0) {
            *d++ = *s++;
        }
    } else {  
        d += n - 1;
        s += n - 1;
        while (n-- > 0) {
            *d-- = *s--;
        }
    }
    return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
    assert(out != NULL && in != NULL);

    unsigned char *dst = out;
    const unsigned char *src = in;

    while (n-- > 0) {
        *dst++ = *src++;
    }

    return out;
    }

int memcmp(const void *s1, const void *s2, size_t n) {
  assert(s1 != NULL && s2 != NULL);

  const unsigned char *tmp1 = s1;
  const unsigned char *tmp2 = s2;
  while (n > 0 && *tmp1 != '\0' && *tmp2 != '\0') {
    if (*tmp1 != *tmp2) {
        return (*tmp1 - *tmp2);
    }
    tmp1++;
    tmp2++;
    n--;
  }
  return 0;
}

#endif
