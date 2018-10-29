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
  provides {
    interface Rtc;
    interface RtcAlarm;
    interface RtcEvent;
  }
  uses {
    interface RtcHWInterrupt;
    interface Panic;
  }
}
implementation {
         rtctime_t  m_last_time;        /* last sec, event, or alarm */
         rtctime_t  m_alarm_time;
  norace uint32_t   m_alarm_fields;     /* checked */
  norace rtcevent_t m_rtc_event;

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
   *
   * WARNING: RTC (in particular, PS) is being clocked async to
   * the processor.  Any reads of the PS register must be done
   * with a majority element because it could be rippling.  This
   * can also effect the other upper registers but this is handled
   * by !RDY code that calls grab_time (see Rtc.getTime()).
   */
  void grab_time(msp432_rtc_t *rtcp) {
    uint16_t ps0, ps1;

    do {
      ps0 = RTC_C->PS;
      ps1 = RTC_C->PS;
      if (ps0 == ps1)
        break;
      ps0 = RTC_C->PS;
      if (ps0 == ps1)
        break;
      ps0 = RTC_C->PS;
    } while (0);
    rtcp->ps     = ps0 & 0x7fff;        /* lose high order bit */
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


  /**
   * Rtc.setTime() and Rtc.syncSetTime() both do the same thing.
   * Rtc is a low level h/w interface and that is why it is async.
   *
   * Under special circumstances, we want to call setTime synchronously.
   * So ...  even though they do the same thing, we provide both.  Typical
   * use is via async setTime().
   */
  command void Rtc.syncSetTime(rtctime_t *timep) {
    call Rtc.setTime(timep);
  }


  async command void Rtc.setTime(rtctime_t *timep) {
    bool running;

    if (!timep)
      call Panic.panic(PANIC_TIME, 0, 0, 0, 0, 0);

    running = rtc_running();
    atomic {
      /* open lock and stop the RTC */
      RTC_C->CTL0 = (RTC_C->CTL0 & ~RTC_C_CTL0_KEY_MASK) | RTC_C_KEY;
      BITBAND_PERI(RTC_C->CTL13, RTC_C_CTL13_HOLD_OFS) = 1;
      RTC_C->TIM0 = timep->min << 8 | timep->sec;
      RTC_C->TIM1 = timep->dow << 8 | timep->hr;
      RTC_C->DATE = timep->mon << 8 | timep->day;
      RTC_C->YEAR = timep->year;

      /* you have to set PS last, TI in their infinite wisdom clears
       * PS when one writes to TIM0.  not sure why, but keeps things
       * interesting.  Not documented in the references.
       */
      RTC_C->PS   = timep->sub_sec;

      if (RTC_C->PS   != timep->sub_sec ||
          RTC_C->TIM0 != (timep->min << 8 | timep-> sec) ||
          RTC_C->TIM1 != (timep->dow << 8 | timep->hr)   ||
          RTC_C->DATE != (timep->mon << 8 | timep->day)  ||
          RTC_C->YEAR != timep->year) {
        call Panic.panic(PANIC_TIME, 1, 0, 0, 0, 0);
      }
      if (running)
        BITBAND_PERI(RTC_C->CTL13, RTC_C_CTL13_HOLD_OFS) = 0;
      BITBAND_PERI(RTC_C->CTL0, RTC_C_CTL0_KEY_OFS) = 0;    /* close lock */
    }
  }


  async command void Rtc.getTime(rtctime_t *timep) {
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
        return;
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
          return;
        }
        old_cur = cur;                 /* swap time space */
        cur     = next;
        next    = old_cur;
      }

      /* something went wrong, shouldn't be here */
      call Panic.panic(PANIC_TIME, 2, (parg_t) cur, (parg_t) next,
                       cur->minsec, next->minsec);
    }
    /* not reached */
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


  /*
   * return true if year is a leap year.
   *
   * Implements the following common Gregorian leap year calculations:
   *
   * 1) if year is evenly divisible by 400, always a leap year.
   * 2) if year is evenly divisible by 100, never a leap year.
   * 3) if year is evenly divisible by 4, leap year.
   * 4) not a leap year.
   *
   * Not valid for BC or BCE year numbering.  We use it for years post 1970.
   */
  bool leapyear(uint32_t year) {
    if (year % 400 == 0) return TRUE;
    if (year % 100 == 0) return FALSE;
    if (year % 4   == 0) return TRUE;
    return FALSE;
  }

  /*
   * number of accumulated days upto the 1st day of the month
   * indexed by (mon - 1).
   */
  const uint16_t accum_days[] =
   /* J   F   M   A    M    J    J    A    S    O    N    D */
    { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 };

  /*
   * return number of days from the beginning of the year to passed in date.
   *
   * Only report full days up to the current day passed in.
   */
  uint32_t datedays(rtctime_t *timep) {
    uint32_t mon;
    uint32_t days;

    if (!timep)
      call Panic.panic(PANIC_TIME, 0, 0, 0, 0, 0);
    if (timep->year != 1970 && !call Rtc.rtcValid(timep))
      call Panic.panic(PANIC_TIME, 1, timep->year, timep->mon, timep->day, 0);
    mon = timep->mon - 1;
    days = accum_days[mon] + timep->day - 1;
    if (mon < 2)                /* january or february*/
      return days;
    if (leapyear(timep->year))
      days++;
    return days;
  }


  /**
   * rtc2epoch: convert an RTC time to a unix epoch.
   * usefull when comparing times or looking at deltas.
   *
   * return is computed since 1970-01-01T00:00:00.000000
   *
   * The return is a fixed point integer.  The upper 32 bits of the return
   * is the number of seconds since 1970-01-01T00:00:00.  While the lower
   * 32 bits is the number of microseconds since the last second.
   *
   * Returns: -1.-1      if time is < 1970.
   *
   * Implements the epoch conversion using unix struct tm algorithm.  See...
   * http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/
   *    V1_chap04.html#tag_04_15  or ...
   *
   * WARNING: we use 32 bit arithmetic for this computation.  It has been
   * tested through 2099 which is the same range that the TI RTC hardware
   * works over.
   */
  async command uint64_t Rtc.rtc2epoch(rtctime_t *timep) {
    uint32_t rtn;
    uint32_t micros;
    uint32_t year;

    if (!timep)
      call Panic.panic(PANIC_TIME, 0, 0, 0, 0, 0);
    if (timep->year < 1970)
      return -1ULL;
    year = timep->year - 1900;
    rtn = (year - 70) * 31536000    +   /* secs/year */
      ((year - 69) /4)   * 86400    +   /* number of modulo 4 leaps */
      ((year + 299)/400) * 86400        /* modulo 400 leaps */
    - ((year - 1)/100)   * 86400    +   /* sub off modulo 100 leaps */
      datedays(timep)    * 86400    +   /* number of days since year start */
      timep->hr          * 3600     +   /* number of secs due to hours */
      timep->min         * 60       +   /* number of secs due to minutes */
      timep->sec;
    micros = call Rtc.subsec2micro(timep->sub_sec);
    return (uint64_t) rtn << 32 | micros;
  }


  /**
   * subsec2micro():
   * Convert subsec units (jiffies) to microseconds.
   *
   * 1 jiffy is 1/32768 secs ~30.5 usecs (decimal usecs).
   *
   * To maintain 32 bit math, we reduce incoming jiffies by appropriate
   * powers of 2 until jiffies is < 4096.  The calculation for 4095 is
   * 4095 * 1000000 = 4095000000 which is less than 4294967296.  This
   * makes the calulation for the remainder.
   */
  async command uint32_t Rtc.subsec2micro(uint16_t jiffies) {
    uint32_t micros;

    micros = 0;
    jiffies &= 0x7fff;                  /* clamp to 32767 */
    if (jiffies > 16383) {
      jiffies  -= 16384;
      micros    = 500000;
    }
    if (jiffies > 8191) {
      jiffies  -= 8192;
      micros   += 250000;
    }
    if (jiffies > 4095) {
      jiffies  -= 4096;
      micros   += 125000;
    }
    micros += (1000000UL * jiffies)/32768;
    return micros;
  }


  /**
   * micro2subsec():
   * Convert microseconds to subsec units (jiffies).
   *
   * similarily to subsec2micro() we reduce jiffies until
   * 32 bit math works.
   */
  async command uint16_t Rtc.micro2subsec(uint32_t micros) {
    uint32_t jiffies;

    if (micros > 999999)                /* sec or greater ? */
      return 32767;                     /* return max value */
    jiffies = 0;
    if (micros > 499999) {
      micros  -= 500000;
      jiffies += 16384;
    }
    if (micros > 249999) {
      micros  -= 250000;
      jiffies += 8192;
    }
    if (micros > 124999) {
      micros  -= 125000;
      jiffies += 4096;
    }
    jiffies += ((32768 * (micros + 16))/1000000);
    return jiffies;
  }


  /*********************************************************************
   *
   * RtcAlarm
   *
   */

  async command error_t RtcAlarm.setAlarm(rtctime_t *timep,
                                          uint32_t field_set) {
    uint16_t aminhr, adowday;

    /*
     * always, start out disabled
     *
     * don't mess with any data structures until after the disable of AIE.
     */
    RTC_C->CTL0 = (RTC_C->CTL0 & ~(RTC_C_CTL0_KEY_MASK |
                                   RTC_C_CTL0_AIE      |
                                   RTC_C_CTL0_AIFG))
                        | RTC_C_KEY;
    RTC_C->CTL0 = 0;                            /* close lock */
    aminhr = adowday = 0;
    m_alarm_fields = 0;                         /* disabled. */
    call Rtc.clearTime(&m_alarm_time);
    RTC_C->AMINHR  = aminhr  = 0;               /* turn all alarm enables off */
    RTC_C->ADOWDAY = adowday = 0;
    if (timep == NULL || field_set == 0)        /* nothing to do. */
      return EOFF;
    do {
      /* validity check but only for those items that are requested. */
      if ((field_set & (RTC_ALARM_YEAR | RTC_ALARM_MON)))
        break;                          /* oops panic */
      if (field_set & RTC_ALARM_DAY) {
        if (timep->day > 31)
          break;                        /* oops panic */
        /* day is the high order, ti's names are stupid */
        adowday |= (timep->day << 8) | RTC_C_ADOWDAY_DAYAE;
      }
      if (field_set & RTC_ALARM_DOW) {
        if (timep->dow > 6)
          break;                        /* oops panic */
        adowday |= timep->dow << 8 | RTC_C_ADOWDAY_DOWAE;
      }
      if (field_set & RTC_ALARM_HOUR) {
        if (timep->hr > 23)
          break;                        /* oops panic */
        aminhr |= (timep->hr << 8) | RTC_C_AMINHR_HOURAE;
      }
      if (field_set & RTC_ALARM_MINUTE) {
        if (timep->min > 59)
          break;                        /* oops.  panic */
        aminhr |= timep->min | RTC_C_AMINHR_MINAE;
      }
      /*
       * lookin good.
       *
       * o remember, time and fields
       * o set the hw alarm registers (not protected)
       * o enable interrupt (protected)
       */
      call Rtc.copyTime(&m_alarm_time, timep);
      m_alarm_fields = field_set;
      RTC_C->AMINHR  = aminhr;
      RTC_C->ADOWDAY = adowday;
      RTC_C->CTL0 = (RTC_C->CTL0 & ~RTC_C_CTL0_KEY_MASK) |
                RTC_C_KEY | RTC_C_CTL0_AIE;
      RTC_C->CTL0 = 0;                  /* close lock */
      return SUCCESS;
    } while (0);
    call Panic.panic(PANIC_TIME, 3, (parg_t) timep, field_set, aminhr, adowday);
    return EINVAL;
  }


  async command uint32_t RtcAlarm.getAlarm(rtctime_t **timepp) {
    if (timepp)
      *timepp = &m_alarm_time;
    return     m_alarm_fields;
  }


  default async event void RtcAlarm.rtcAlarm(rtctime_t *timep,
                                             uint32_t field_set) { }


  async event void RtcHWInterrupt.alarmInterrupt() {
    call Rtc.getTime(&m_last_time);
    signal RtcAlarm.rtcAlarm(&m_last_time, m_alarm_fields);
  }


  /*********************************************************************
   *
   * RtcEvent
   *
   */

  async command void RtcEvent.setEventMode(rtcevent_t event_mode) {
    uint16_t tev;

    /* start out disabled */
    RTC_C->CTL0 = (RTC_C->CTL0 & ~(RTC_C_CTL0_KEY_MASK |
                                   RTC_C_CTL0_TEVIE    |
                                   RTC_C_CTL0_RDYIE    |
                                   RTC_C_CTL0_TEVIFG   |
                                   RTC_C_CTL0_RDYIFG))
                        | RTC_C_KEY;
    RTC_C->CTL0 = 0;                    /* close lock */
    m_rtc_event = event_mode;
    switch (event_mode) {
      case RTC_EVENT_NONE:
        return;

      case RTC_EVENT_SEC:
        RTC_C->CTL0 = (RTC_C->CTL0 & ~RTC_C_CTL0_KEY_MASK) |
                       RTC_C_CTL0_RDYIE    |
                       RTC_C_KEY;
        RTC_C->CTL0 = 0;                /* close lock */
        return;

      case RTC_EVENT_MIN:       tev = 0; break;
      case RTC_EVENT_HOUR:      tev = 1; break;
      case RTC_EVENT_0000:      tev = 2; break;
      case RTC_EVENT_1200:      tev = 3; break;

      default:
        call Panic.panic(PANIC_TIME, 4, event_mode, 0, 0, 0);
        return;
    }
    /* unlock */
    RTC_C->CTL0 = (RTC_C->CTL0 & ~RTC_C_CTL0_KEY_MASK) | RTC_C_KEY;
    RTC_C->CTL13 = (RTC_C->CTL13 & ~RTC_C_CTL13_TEV_MASK) | tev;
    RTC_C->CTL0 = (RTC_C->CTL0 & ~RTC_C_CTL0_KEY_MASK) |
                   RTC_C_CTL0_TEVIE                    |
                   RTC_C_KEY;
    RTC_C->CTL0 = 0;                /* close lock */
  }


  async command rtcevent_t RtcEvent.getEventMode() {
    return m_rtc_event;
  }


  default async event void RtcEvent.rtcEvent(rtctime_t *timep,
                                             rtcevent_t rtc_event) { }


  async event void RtcHWInterrupt.secInterrupt() {
    call Rtc.getTime(&m_last_time);
    signal RtcEvent.rtcEvent(&m_last_time, RTC_EVENT_SEC);
  }

  async event void RtcHWInterrupt.eventInterrupt() {
    call Rtc.getTime(&m_last_time);
    signal RtcEvent.rtcEvent(&m_last_time, m_rtc_event);
  }

  async event void Panic.hook() { }
}
