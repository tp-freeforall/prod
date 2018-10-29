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

/**
 * Interface to the ti msp432 real-time clock.
 *
 * This interface assumes hardware support for a calendar-based clock
 * including date and time, with sub-second resolution provided by the
 * msp432 rtc hardware.
 *
 * This interface is intended to be a reasonable abstraction of typical
 * RTC h/w.  It is based on the TI MSP432 RTC h/w.
 */

interface Rtc {

  /**
   * Basic Rtc access
   */
  async command void rtcStop();
  async command void rtcStart();

  /**
   * rtcValid
   *
   * return TRUE if we think the time is valid.
   *
   * Currently this means that all fields of the RTC are within range,
   * sec, min, hr, dow, day, and mon.  We also check for year being
   * between 2018 and 2099 inclusive.
   *
   * One must fetch the current time value from the h/w via getTime().
   */
  async command bool rtcValid(rtctime_t *time);


  /**
   * set the rtc time.
   *
   * its hardware, can't fail.  If it fails, the driver panics.
   * null pointers are also caught by 0 panics.
   *
   * we provide both sync and async versions.   Normally the async
   * version is used.  Sync is a special case.
   */
        command void syncSetTime(rtctime_t *timep);
  async command void setTime(rtctime_t *timep);


  /**
   * getTime
   *
   * get current time.  non split-phase
   */
  async command void getTime(rtctime_t *timep);


  /**
   * clrTime
   *
   * zero the time structure.
   */
  async command void clearTime(rtctime_t *timep);


  /**
   * copyTime
   *
   * copy one time structure to another.
   */
  async command void copyTime(rtctime_t *dtimep, rtctime_t *stimep);


  /**
   * compareTimes
   *
   * compares two rtctimes and returns less, equal, or greater
   *
   * input:     time0p  pointer to an rtc time
   *            time1p  pointer to 2nd rtc time
   *
   * output:    return  -1, time0  < time1
   *                     0, time0 == time1
   *                     1, time0  > time1
   */
  async command int compareTimes(rtctime_t *time0p, rtctime_t *time1p);


  /**
   * Convert an rtctime to an epoch time.
   *
   * Compute the number of microseconds since 1970-1-1 00:00:00.000000 UTC.
   * The Unix epoch.
   */
  async command uint64_t rtc2epoch(rtctime_t *timep);


  /**
   * subsec2micro():
   * micro2subsec():
   *
   * Convert subsec units (jiffies) to microseconds.
   * Convert microseconds to subsec units (jiffies).
   *
   * 1 jiffy is 1/32768 secs ~30.5 usecs (decimal usecs).
   */
  async command uint32_t subsec2micro(uint16_t jiffies);
  async command uint16_t micro2subsec(uint32_t micros);
}
