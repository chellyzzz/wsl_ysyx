#include <am.h>
#include <nemu.h>

void __am_timer_init() {
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uint32_t lo = inl(RTC_ADDR);
  uint64_t hi = inl(RTC_ADDR + 4);
  uptime->us = (hi << 32) + lo;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}

// static uint64_t boot_time;

// uint64_t getitimer(){
//   uint32_t low = inl(RTC_ADDR);
//   uint32_t high = inl(RTC_ADDR + 4);
//   return ((uint64_t)low + (((uint64_t)high) << 32));
// }
// void __am_timer_init() {
//   boot_time = getitimer();
// }

// void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
//   uptime->us = getitimer() - boot_time;
// }

// void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
//   rtc->second = 0;
//   rtc->minute = 0;
//   rtc->hour   = 0;
//   rtc->day    = 0;
//   rtc->month  = 0;
//   rtc->year   = 1900;
// }
