#include <common.h>

#if defined(MULTIPROGRAM) && !defined(TIME_SHARING)
# define MULTIPROGRAM_YIELD() yield()
#else
# define MULTIPROGRAM_YIELD()
#endif

#define NAME(key) \
  [AM_KEY_##key] = #key,

static const char *keyname[256] __attribute__((used)) = {
  [AM_KEY_NONE] = "NONE",
  AM_KEYS(NAME)
};

size_t serial_write(const void *buf, size_t offset, size_t len) {
  char *cbuf = (char *)buf;
  for(int i = 0; i < len; i++){
    putch(cbuf[i]);
  }
  return len;
}

size_t events_read(void *buf, size_t offset, size_t len) {
  AM_INPUT_KEYBRD_T ev = io_read(AM_INPUT_KEYBRD);
  if (ev.keycode == AM_KEY_NONE) {
    *(char*)buf = '\0';
    return 0;
  }
  else {
    int key = ev.keycode;
    if (ev.keydown) {
      snprintf((char*)buf, len, "kd %s\n", keyname[key]);
    }
    else {
      snprintf((char*)buf, len, "ku %s\n", keyname[key]);
    }
    return strlen((char*)buf);
  }
}

size_t dispinfo_read(void *buf, size_t offset, size_t len) {
  AM_GPU_CONFIG_T cfg = io_read(AM_GPU_CONFIG);  
  return snprintf((char *)buf, len, "Width:%d\nHeight:%d\n", cfg.width, cfg.height);
}

size_t fb_write(const void *buf, size_t offset, size_t len) {
  AM_GPU_FBDRAW_T fbctl;
  AM_GPU_CONFIG_T cfg = io_read(AM_GPU_CONFIG);  
  fbctl.pixels = (void *)buf;

  fbctl.x = offset % cfg.width;
  fbctl.y = offset / cfg.width;
  fbctl.w      = len;
  fbctl.h      =  1;
  fbctl.sync   = true;
  ioe_write(AM_GPU_FBDRAW, &fbctl);
  return len;
}

void init_device() {
  Log("Initializing devices...");
  ioe_init();
}
