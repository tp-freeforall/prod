/*
 * Copyright (c) 2018 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <rtc.h>
#include <rtctime.h>
#include <platform_panic.h>

#ifndef PANIC_TIME
enum {
  __pcode_time = unique(UQ_PANIC_SUBSYS)
};

#define PANIC_TIME __pcode_time
#endif

module Msp432RtcP {
  provides interface Rtc;
  uses     interface Panic;
}
implementation {

  /*
   * low level functions are callable by low level functions
   * used by start up code.
   */
  void __get_rtc_time(rtctime_t *timep) @C() {
    if (!timep)
      call Panic.panic(PANIC_TIME, 0, 0, 0, 0, 0);
  }


  bool __valid_time(rtctime_t *timep) @C() {
    if (!timep)
      call Panic.panic(PANIC_TIME, 0, 0, 0, 0, 0);
    if (timep->year < 2018 || timep->year > 2099 ||
        timep->mon == 0    || timep->mon > 12    ||
        timep->day == 0    || timep->mon > 31    ||
        timep->dow  > 6    || timep->hr  > 23    ||
        timep->min  > 59   || timep->sec > 59)
      return FALSE;
    return TRUE;
  }


  bool rtcRunning() {
    if (RTC_C->CTL13 & RTC_C_CTL13_HOLD)
      return FALSE;
    return TRUE;
  }


  async command void Rtc.rtcStop() {
    BITBAND_PERI(RTC_C->CTL13, RTC_C_CTL13_HOLD_OFS) = 1;
  }


  async command void Rtc.rtcStart() {
    BITBAND_PERI(RTC_C->CTL13, RTC_C_CTL13_HOLD_OFS) = 0;
  }


  async command bool Rtc.rtcValid() {
    rtctime_t time;

    __get_rtc_time(&time);
    return __valid_time(&time);
  }


  async command error_t Rtc.setTime(rtctime_t *timep) {
    bool running;

    if (!timep)
      call Panic.panic(PANIC_TIME, 0, 0, 0, 0, 0);

    running = rtcRunning();
    atomic {
      call Rtc.rtcStop();
      RTC_C->PS = timep->sub_sec;
      RTC_C->TIM0 = timep->min << 8 | timep->sec;
      RTC_C->TIM1 = timep->dow << 8 | timep->hr;
      RTC_C->DATE = timep->mon << 8 | timep->day;
      RTC_C->YEAR = timep->year;
      if (running)
        call Rtc.rtcStart();
    }
    return SUCCESS;
  }


  async command error_t Rtc.getTime(rtctime_t *timep) {
    if (!timep)
      call Panic.panic(PANIC_TIME, 0, 0, 0, 0, 0);
    __get_rtc_time(timep);
    return SUCCESS;
  }


  async command void Rtc.clearTime(rtctime_t *timep) {
    if (!timep)
      call Panic.panic(PANIC_TIME, 0, 0, 0, 0, 0);
    memset((void *) timep, 0, sizeof(rtctime_t));
  }


  async command void Rtc.copyTime(rtctime_t *dtimep, rtctime_t *stimep) {
    if (!dtimep || !stimep)
      call Panic.panic(PANIC_TIME, 0, 0, 0, 0, 0);
    memcpy((void *) dtimep, (void *) stimep, sizeof(rtctime_t));
  }


  async command error_t Rtc.requestTime(uint32_t event_code) {
    return FAIL;
  }


  async command error_t Rtc.setEventMode(RtcEvent_t event_mode) {
    return FAIL;
  }


  async command RtcEvent_t Rtc.getEventMode() {
    return RTC_EVENT_NONE;
  }


  async command error_t Rtc.setAlarm(rtctime_t *timep, uint32_t field_set) {
    return FAIL;
  }


  async command uint32_t Rtc.getAlarm(rtctime_t *timep) {
    return 0;
  }


  default async event void Rtc.currentTime(rtctime_t *timep,
                                           uint32_t reason_set) { }

  async event void Panic.hook() { }
}
