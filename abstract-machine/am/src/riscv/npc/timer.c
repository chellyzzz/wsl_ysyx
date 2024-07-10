#include <am.h>
#include <npc.h>

static uint64_t boot_time;

uint64_t rtc_get_time() {
  uint32_t lo = inl(RTC_ADDR);
  // uint32_t hi = inl(RTC_ADDR + 4);
  return (uint64_t)lo;
}

void __am_timer_init() {
    boot_time = rtc_get_time();
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {

  uptime->us = 2*rtc_get_time() - boot_time;

}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}