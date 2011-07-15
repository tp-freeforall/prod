/* Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
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

#include "RealTimeClock.h"

module PlatformRealTimeClockP {
  provides {
    interface StdControl;
    interface RealTimeClock;
  }
} implementation {

/* TI renamed RTC_A_VECTOR to RTC_VECTOR in more recent header
 * releases.  Use the former if we don't have the latter. */

#ifndef RTC_VECTOR
#define RTC_VECTOR RTC_A_VECTOR
#endif /* RTC_VECTOR */

/* Alarm Enable bit for alarm registers */
#ifndef RTC_AE
#define RTC_AE 0x80
#endif /* RTC_AE */

  /** User-requested event codes */
  unsigned int eventSet__;

  command error_t StdControl.start () {
    atomic {
      /* Remove hold, calendar mode, binary values, source ACLK */
      RTCCTL01 = RTCMODE;
      /* Clear the event mask */
      eventSet__ = 0;
    }
    return SUCCESS;
  }

  command error_t StdControl.stop () {
    atomic {
      RTCCTL01 |= RTCHOLD;
    }
    return SUCCESS;
  }

  command error_t RealTimeClock.setTime (const struct tm* time) {
    if (! time) {
      return EINVAL;
    }
    atomic {
      if (RTCHOLD & RTCCTL01) {
        return EOFF;
      }
      RTCCTL01 |= RTCHOLD;
      RTCSEC = time->tm_sec;
      RTCMIN = time->tm_min;
      RTCHOUR = time->tm_hour;
      RTCDOW = time->tm_wday;
      RTCDAY = time->tm_mday;
      RTCMON = 1 + time->tm_mon;
      RTCYEAR = 1900 + time->tm_year;
      RTCCTL01 &= ~RTCHOLD;
    }
    return SUCCESS;
  }

  command error_t RealTimeClock.requestTime (unsigned int event_set) {
    atomic {
      if (RTCCTL01 & RTCHOLD) {
        return EOFF;
      }
      eventSet__ |= event_set;
      RTCCTL01 |= RTCRDYIE;
      return SUCCESS;
    }
  }

  command error_t RealTimeClock.setIntervalMode (RtcIntervalMode_e interval_mode) {
    error_t rv = SUCCESS;

    atomic {
      /* Start by disabling any interval-related interrupt */
      RTCCTL01 &= ~(RTCTEVIE | RTCTEVIFG);
      if (RTC_INTERVAL_MODE_NONE == interval_mode) {
        /* Leave everything disabled */
        ;
      } else {
        uint16_t rtctev = 0;

        /* Turn on the selected event, or return an error if the
         * argument was bogus */
        switch (interval_mode) {
          case RTC_INTERVAL_MODE_MIN:
            rtctev = RTCTEV__MIN;
            break;
          case RTC_INTERVAL_MODE_HOUR:
            rtctev = RTCTEV__HOUR;
            break;
          case RTC_INTERVAL_MODE_1200:
            rtctev = RTCTEV__1200;
            break;
          case RTC_INTERVAL_MODE_0000:
            rtctev = RTCTEV__0000;
            break;
          default:
            rv = EINVAL;
            break;
        }
        if (SUCCESS == rv) {
          RTCCTL01 = (RTCCTL01 & ~(RTCTEV0 | RTCTEV1)) | RTCTEVIE | rtctev;
        }
      }
    }
    return rv;
  }

  command RtcIntervalMode_e RealTimeClock.getIntervalMode () {
    atomic {
      if (! (RTCTEVIE & RTCCTL01)) {
        return RTC_INTERVAL_MODE_NONE;
      }
      switch (RTCCTL01 & (RTCTEV0 | RTCTEV1)) {
        case RTCTEV__MIN:
          return RTC_INTERVAL_MODE_MIN;
        case RTCTEV__HOUR:
          return RTC_INTERVAL_MODE_HOUR;
        case RTCTEV__1200:
          return RTC_INTERVAL_MODE_1200;
        case RTCTEV__0000:
          return RTC_INTERVAL_MODE_0000;
      }
    }
    /*NOTREACHED*/
    return RTC_INTERVAL_MODE_NONE;
  }

  command error_t RealTimeClock.setAlarm (const struct tm* time,
                                          unsigned int field_set) {
    atomic {
      /* Start by disabling the alarm */
      RTCCTL0 &= ~(RTCAIE | RTCAIFG);
      if (time) {
        RTCAMIN = time->tm_min;
        RTCAHOUR = time->tm_hour;
        RTCADOW = time->tm_wday;
        RTCADAY = time->tm_mday;
      } else {
        RTCAMIN = RTCAHOUR = RTCADOW = RTCADAY = 0;
      }
      if (field_set & RTC_ALARM_MINUTE) {
        RTCAMIN |= RTC_AE;
      }
      if (field_set & RTC_ALARM_HOUR) {
        RTCAHOUR |= RTC_AE;
      }
      if (field_set & RTC_ALARM_DOW) {
        RTCADOW |= RTC_AE;
      }
      if (field_set & RTC_ALARM_DOM) {
        RTCADAY |= RTC_AE;
      }
      if (field_set) {
        RTCCTL0 |= RTCAIE;
      }
    }
    return SUCCESS;
  }

  command unsigned int RealTimeClock.getAlarm (struct tm* time) { return 0; }

  default async event void RealTimeClock.currentTime (const struct tm* timep,
                                                      unsigned int reason_set) { }

  TOSH_SIGNAL(RTC_VECTOR) {
    struct tm now;
    int time_is_valid;
    volatile uint16_t rtciv;

    /* The only reason we should ever get an interrupt is that
     * something happened for which we want the time.  In some cases,
     * RTCRDY may be reset at the time the event is signalled.  For
     * example, this happens with RTCAIFG.  Similarly, any use of a
     * prescale-based interval event is not synchronized with RTC
     * register updates.
     *
     * What we do is set RTCRDYIE, then sample RTCRDY.  If it's good,
     * we proceed with the read, then resample it again at the end.
     * If it's still good, the time is valid, and we clear RTCRDYIE,
     * do whatever else we need to do, and signal the user.
     *
     * If we didn't read a valid time, we just accumulate the reasons,
     * and leave RTCRDYIE enabled so we get another interrupt as soon
     * as the time is valid.
     */

    RTCCTL01 |= RTCRDYIE;
    memset(&now, 0, sizeof(now));
    time_is_valid = RTCRDY & RTCCTL01;
    if (time_is_valid) {
      now.tm_sec = RTCSEC;
      now.tm_min = RTCMIN;
      now.tm_hour = RTCHOUR;
      now.tm_wday = RTCDOW;
      now.tm_mday = RTCDAY;
      now.tm_mon = RTCMON - 1;
      now.tm_year = RTCYEAR - 1900;
      time_is_valid = RTCRDY & RTCCTL01;
    }
    if (time_is_valid) {
      RTCCTL01 &= ~(RTCRDYIE | RTCRDYIFG);
    }

    do {
      rtciv = RTCIV;
      switch (rtciv) {
        case RTC_RTCRDYIFG:    /* RTC ready: RTCRDYIFG */
          eventSet__ |= RTC_REASON_NONE;
          break;
        case RTC_RTCTEVIFG:    /* RTC interval timer: RTCTEVIFG */
        case RTC_RT1PSIFG:     /* RTC prescaler 1: RT1PSIFG */
          eventSet__ |= RTC_REASON_INTERVAL;
          break;
        case RTC_RTCAIFG:      /* RTC user alarm: RTCAIFG */
          eventSet__ |= RTC_REASON_ALARM;
          break;
        default:
        case RTC_NONE:   /* No Interrupt pending */
        case RTC_RT0PSIFG:     /* RTC prescaler 0: RT0PSIFG */
          break;
      }
    } while (RTC_NONE != rtciv);

    if (time_is_valid) {
      unsigned int event_set = eventSet__;
      eventSet__ = 0;
      signal RealTimeClock.currentTime(&now, event_set);
    }
  }
}
