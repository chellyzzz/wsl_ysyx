#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>

static int evtdev = -1;
static int fbdev = -1;
static int screen_w = 0, screen_h = 0;
static int window_w = 0, window_h = 0;
static int offset_x = 0, offset_y = 0;
static uint32_t init_time = 0;

uint32_t NDL_GetTicks() {
  struct timeval time;
  gettimeofday(&time, NULL);
  return time.tv_sec * 1000 + time.tv_usec / 1000 - init_time;
}

int NDL_PollEvent(char *buf, int len) {
  int fd = open("/dev/events",0,0);
  return read(fd, buf, len);
}

void NDL_OpenCanvas(int *w, int *h) {
  char dispinfo[32];
  int dispinfo_fd = open("/proc/dispinfo",0,0); 
  read(dispinfo_fd, dispinfo, sizeof(dispinfo));
  sscanf(dispinfo,"Width:%d\nHeight:%d\n",&screen_w,&screen_h);
  close(dispinfo_fd);

  if(*w ==0 && *h==0){
    *w = screen_w;
    *h = screen_h;
  }
  else if(*w > screen_w || *h > screen_h){
    printf("Window size exceeds screen size\n");
    exit(1);
  }
  offset_x = (screen_w - *w) / 2;
  offset_y = (screen_h - *h) / 2;
  window_w = *w;
  window_h = *h;
  //
  if (getenv("NWM_APP")) {
    int fbctl = 4;
    fbdev = 5;
    screen_w = *w; screen_h = *h;
    char buf[64];
    int len = sprintf(buf, "%d %d", screen_w, screen_h);
    // let NWM resize the window and create the frame buffer
    write(fbctl, buf, len);
    while (1) {
      // 3 = evtdev
      int nread = read(3, buf, sizeof(buf) - 1);
      if (nread <= 0) continue;
      buf[nread] = '\0';
      if (strcmp(buf, "mmap ok") == 0) break;
    }
    close(fbctl);
  }
  printf("Window size: %d x %d\n", *w, *h);
  printf("Screen size: %d, %d\n", screen_w, screen_h);

}

void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h) {
  printf("offset size: %d x %d\n", offset_x, offset_y);
  int fd = open("/dev/fb",0);
  printf("fd: %d\n", fd);
  uint32_t *p = pixels;
  x = offset_x + x;
  y = offset_y + y;
  printf("x: %d, y: %d, w: %d, h: %d\n", x, y, w, h);
  size_t offset = screen_w * y + x;
  lseek(fd, offset, SEEK_SET);
  for(int i = 0; i < h; i ++){
    write(fd, p, w);
    offset += screen_w;
    printf("draw offset: %d\n", offset);
    lseek(fd, offset, SEEK_SET);
    p += w;
  }
} 


void NDL_OpenAudio(int freq, int channels, int samples) {
}

void NDL_CloseAudio() {
}

int NDL_PlayAudio(void *buf, int len) {
  return 0;
}

int NDL_QueryAudio() {
  return 0;
}

int NDL_Init(uint32_t flags) {
  if (getenv("NWM_APP")) {
    evtdev = 3;
  }
  init_time = NDL_GetTicks();
  return 0;
}

void NDL_Quit() {
}
