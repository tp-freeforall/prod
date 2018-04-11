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


typedef struct {
  uint16_t ps;
  uint16_t minsec;
  uint16_t dowhr;
  uint16_t monday;
  uint16_t year;
} msp432_rtc_t;


module Msp432RtcP {
  provides interface Rtc;
  uses     interface Panic;
}
implementation {

  /**
   * grab_time(): grab time from the msp432 RTC registers
   *
   * snag all 5 RTC registers and place into an msp432_rtc_t struct.
   *
   * We nuke the high order bit of PS because PS should go from
   * 0 to 32767 jiffies.  which is 0.000000 to 0.999969 secs.  The
   * high order bit is outside this range.
   *
   *** must be inside an atomic ***
   */
  void grab_time(msp432_rtc_t *rtcp) {
    rtcp->ps     = RTC_C->PS & 0x7fff;  /* lose high order bit */
    rtcp->minsec = RTC_C->TIM0;
    rtcp->dowhr  = RTC_C->TIM1;
    rtcp->monday = RTC_C->DATE;
    rtcp->year   = RTC_C->YEAR;
  }


  /*
   * check_time: check two msp432 times for upper equivilence.
   *
   * want to make sure that secs and above values all match.
   * we don't care about the PS values.
   *
   * takes pointers to two msp432_rtc structures
   *
   * returns: TRUE if all uper values (secs and above) match
   *          FALSE otherwise.
   */
  bool check_time(msp432_rtc_t *rtc0, msp432_rtc_t *rtc1) {
    if (rtc0->minsec != rtc1->minsec)
      return FALSE;
    if (rtc0->dowhr != rtc1->dowhr)
      return FALSE;
    if (rtc0->monday != rtc1->monday)
      return FALSE;
    if (rtc0->year != rtc1->year)
      return FALSE;
    return TRUE;
  }


  void set_timep(rtctime_t *timep, msp432_rtc_t *rtcp) {
    timep->sub_sec = rtcp->ps;
    timep->sec     = rtcp->minsec & 0xff;
    timep->min     = (rtcp->minsec >> 8) & 0xff;
    timep->hr      = rtcp->dowhr & 0xff;
    timep->dow     = (rtcp->dowhr >> 8) & 0xff;
    timep->day     = rtcp->monday & 0xff;
    timep->mon     = (rtcp->monday >> 8) & 0xff;
    timep->year    = rtcp->year;
  }


  bool rtc_running() {
    if (RTC_C->CTL13 & RTC_C_CTL13_HOLD)
      return FALSE;
    return TRUE;
  }


  async command void Rtc.rtcStop() {
    RTC_C->CTL0 = (RTC_C->CTL0 & ~RTC_C_CTL0_KEY_MASK) | RTC_C_KEY;
    BITBAND_PERI(RTC_C->CTL13, RTC_C_CTL13_HOLD_OFS) = 1;
    BITBAND_PERI(RTC_C->CTL0, RTC_C_CTL0_KEY_OFS) = 0;      /* close lock */
  }


  async command void Rtc.rtcStart() {
    RTC_C->CTL0 = (RTC_C->CTL0 & ~RTC_C_CTL0_KEY_MASK) | RTC_C_KEY;
    BITBAND_PERI(RTC_C->CTL13, RTC_C_CTL13_HOLD_OFS) = 0;
    BITBAND_PERI(RTC_C->CTL0, RTC_C_CTL0_KEY_OFS) = 0;      /* close lock */
  }


  async command bool Rtc.rtcValid(rtctime_t *timep) {
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


  async command error_t Rtc.setTime(rtctime_t *timep) {
    bool running;

    if (!timep)
      call Panic.panic(PANIC_TIME, 0, 0, 0, 0, 0);

    running = rtc_running();
    atomic {
      /* open lock and stop the RTC */
      RTC_C->CTL0 = (RTC_C->CTL0 & ~RTC_C_CTL0_KEY_MASK) | RTC_C_KEY;
      BITBAND_PERI(RTC_C->CTL13, RTC_C_CTL13_HOLD_OFS) = 1;
      RTC_C->PS   = timep->sub_sec;
      RTC_C->TIM0 = timep->min << 8 | timep->sec;
      RTC_C->TIM1 = timep->dow << 8 | timep->hr;
      RTC_C->DATE = timep->mon << 8 | timep->day;
      RTC_C->YEAR = timep->year;
      if (running)
        BITBAND_PERI(RTC_C->CTL13, RTC_C_CTL13_HOLD_OFS) = 0;
      BITBAND_PERI(RTC_C->CTL0, RTC_C_CTL0_KEY_OFS) = 0;    /* close lock */
    }
    return SUCCESS;
  }


  async command error_t Rtc.getTime(rtctime_t *timep) {
    msp432_rtc_t rtc0, rtc1;
    msp432_rtc_t *old_cur, *cur, *next;
    int i;

    if (!timep)
      call Panic.panic(PANIC_TIME, 0, 0, 0, 0, 0);

    if (RTC_C->CTL13 & RTC_C_CTL13_RDY) {
      /*
       * The MSP432 RTC has holdoff logic.  The RDY bit will
       * be off if we are within the holdoff window (128/32768)
       * centered around clocking the SEC register.
       *
       * If RDY is set, then we can just do a direct read of the
       * RTC registers and be done with it.
       */
      atomic {
        grab_time(&rtc0);
        set_timep(timep, &rtc0);
        return SUCCESS;
      }
    }

    /*
     * RDY bit is off, this means that there may be a clock into
     * SECs at anytime with the associated clocking ripple to the
     * higher order registers.
     *
     * There is only one clock per our access here.  There won't be
     * another clock for another ~30.5us (1/32768 secs).
     *
     * lets call our different reads, time0, time1, time2, and time3.
     * read time0, read time1, compare time0 and time1.  If uppers match
     * we are good to go.
     *
     * If they don't match we need to do at least one more read.  time2
     * get read (which has to be after time1).  If time1 and time2 don't
     * match than we need one more read, time3.  See below for why this
     * may be needed.  A read of a time involves reading 5 16 bit registers.
     * This takes finite time and the clock is asynchronous to these
     * reads.
     *
     * In the code we use cur and next.  let time[i] be the 1st
     * time read of our current iteration and time[i+1] is the
     * second read.
     *
     *      cur        points at time[i], the first read.
     *      next       points at time[i+1] the second read.
     *
     * Here are the different possibilites:
     *
     *   < time   - means clock occured prior to time.
     *   | time | - means clock occurred during the read of time.
     *   > time   - means clock occured after reading of time.
     *
     * cur->uppers are all fields of cur not including sub_sec.
     *
     * for a given iteration, i:
     *
     *   < cur  -  cur->uppers == next->uppers -> done.
     *   > next -  cur->uppers == next->uppers -> done.
     *
     * cur->uppers != next.uppers,  we need to read new time.
     *   old_cur is previous cur
     *   cur     is old_new
     *   next    read new time.
     *
     *  | old_cur | -  cur.uppers == next.uppers -> done.
     *  |   cur   | -  cur.uppers != next.uppers, read a new time
     *
     *   cur     is old_new
     *   next    read new time.
     *
     * cur->uppers == next->uppers, good to go.
     * cur->uppers != next->uppers, something went wrong
     *                             shouldn't happen.
     */
    atomic {
      cur = &rtc0;
      next = &rtc1;
      grab_time(cur);
      for (i = 0; i < 3; i++) {         /* time index */
        grab_time(next);
        if (check_time(cur, next)) {
          set_timep(timep, cur);
          return SUCCESS;
        }
        old_cur = cur;                 /* swap time space */
        cur     = next;
        next    = old_cur;
      }

      /* something went wrong, shouldn't be here */
      call Panic.panic(PANIC_TIME, 1, (parg_t) cur, (parg_t) next,
                       cur->minsec, next->minsec);
      return FAIL;
    }
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


  /**
   * compareTimes: compare two rtc times
   *
   * time0  < time1, return -1
   * time0 == time1, return  0
   * time0  > time1, return  1
   *
   * rtctime is a 10 byte aligned structure.  The year is a 2 byte half-word.
   *
   * We first check years.  If the year is equal we extract the next 4 bytes,
   * mon/day and dow/hr.  If those are equal we do the bottom 4 bytes,
   * min/sec and sub_sec.
   *
   * We originally tried extracting 8 bytes for the compares but couldn't be the
   * placement of individual bytes to work properly, so have resorted to 4 byte
   * quads.  The Cortex-4M is after all a 32 bit machine.
   */

  async command int Rtc.compareTimes(rtctime_t *time0p, rtctime_t *time1p) {
    uint32_t time0u, time0l, time1u, time1l;

    if (!time0p || !time1p)
      call Panic.panic(PANIC_TIME, 0, 0, 0, 0, 0);
    if (time0p->year < time1p->year)
      return -1;
    if (time0p->year > time1p->year)
      return 1;

    time0u = (time0p->mon << 24) | (time0p->day << 16) |
      (time0p->dow <<  8) | time0p->hr;
    time1u = (time1p->mon << 24) | (time1p->day << 16) |
      (time1p->dow << 8) | time1p->hr;
    if (time0u < time1u)
      return -1;
    if (time0u > time1u)
      return 1;

    time0l = (time0p->min << 24) | (time0p->sec << 16) | time0p->sub_sec;
    time1l = (time1p->min << 24) | (time1p->sec << 16) | time1p->sub_sec;
    if (time0l < time1l)
      return -1;
    if (time0l > time1l)
      return 1;
    return 0;
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


  /*************************************************************************
   *
   * low level functions are callable by startup routines.
   */

  void __rtc_rtcStart() @C() @spontaneous() {
    call Rtc.rtcStart();
  }

  error_t __rtc_setTime(rtctime_t *timep) @C() @spontaneous() {
    return call Rtc.setTime(timep);
  }

  error_t __rtc_getTime(rtctime_t *timep) @C() @spontaneous() {
    return call Rtc.getTime(timep);
  }

  bool __rtc_rtcValid(rtctime_t *timep) @C() @spontaneous() {
    return call Rtc.rtcValid(timep);
  }

  int __rtc_compareTimes(rtctime_t *time0p, rtctime_t *time1p) @C() @spontaneous() {
    return call Rtc.compareTimes(time0p, time1p);
  }

}
