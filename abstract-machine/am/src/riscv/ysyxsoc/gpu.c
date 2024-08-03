#include <am.h>
#include <ysyxsoc.h>

#define HEIGHT  480
#define WIDTH   640

void __am_gpu_init() {
    //TODO: get the correct width and height
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = WIDTH, .height = HEIGHT,
    .vmemsz = 0
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
    int x = ctl->x, y = ctl->y, w = ctl->w, h = ctl->h;
    uint32_t *pixels = ctl->pixels;
    if(w == 0 || h == 0) return;
    uint32_t *fb = (uint32_t *)FB_ADDR;
    for (int i = y; i < y + h; i++) {
        for (int j = x; j < x + w; j++) {
        fb[WIDTH*i+j] = pixels[w*(i-y)+(j-x)];
        }
    }
    // outl(SYNC_ADDR, 1);
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
