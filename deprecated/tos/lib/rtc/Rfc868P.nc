/*
 * Copyright (c) 2010 People Power Co.
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

/** Implement conversions between RFC868 seconds-since-epoch and
 * standard struct tm breakdowns.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

module Rfc868P {
  provides {
    interface Rfc868;
  }
} implementation {

#define SECONDS_PER_MINUTE (60)
#define SECONDS_PER_HOUR  (60L * SECONDS_PER_MINUTE)
#define SECONDS_PER_DAY (24L * SECONDS_PER_HOUR)

/** RFC868 epoch is 1900-01-01T00:00:00Z which was a Monday */
#define EPOCH_WDAY (1)
#define DAYS_PER_WEEK (7)
#define DAYS_PER_YEAR (365)
#define MONTH_IDX_FEBRUARY (1)

  static const uint8_t daysPerMonth[] = { 31, 28, 31, 30, 31, 30,
                                          31, 31, 30, 31, 30, 31 };

  /* Convert a POSIX tm structure to an RFC868 time (seconds since
   * 1900-01-01T00:00:00Z), without assuming that day-of-year is valid
   * on input
   */
  command uint32_t Rfc868.fromTime (const struct tm* time) {
    uint32_t time_sec = 0;
    unsigned int days_since_epoch;
    int is_leap_year;
    int i;

    time_sec = time->tm_sec;
    time_sec += time->tm_min * SECONDS_PER_MINUTE;
    time_sec += time->tm_hour * SECONDS_PER_HOUR;

    /* 1900CE (year zero) is the only leap year in the representable
     * range that is not correctly identified by checking for a multiple
     * of four
     */
    is_leap_year = (0 == (time->tm_year % 4)) && (0 != time->tm_year);

    days_since_epoch = time->tm_mday - 1;
    for (i = 0; i < time->tm_mon; ++i) {
      days_since_epoch += daysPerMonth[i];
      if (is_leap_year && (MONTH_IDX_FEBRUARY == i)) {
        ++days_since_epoch;
      }
    }
    for (i = time->tm_year - 1; 0 <= i; --i) {
      days_since_epoch += DAYS_PER_YEAR;
      if ((0 == (i % 4)) && (0 != i)) {
        ++days_since_epoch;
      }
    }
    time_sec += days_since_epoch * SECONDS_PER_DAY;
    return time_sec;
  }

  /* Convert an RFC868 time (seconds since 1900-01-01T00:00:00Z) into
   * a POSIX tm structure, including correct values for day-of-week
   * and day-of-year
   */
  command error_t Rfc868.toTime (uint32_t time_rfc868,
                                 struct tm* time) {
    int is_leap_year;
    unsigned int days_since_epoch;
    int days_per_year;
    long int seconds_per_year;
    int days_per_month;
    long int seconds_per_month;

    if (! time) {
      return EINVAL;
    }
    memset(time, 0, sizeof(*time));

    /* To simplify the loop, we adjust for the previous year before
     * calculating the adjustment for the current year to see if it
     * needs to be applied.  Note that we have to special-case 1900,
     * which is not a leap year though it is exactly divisible by
     * four.
     */
    time->tm_year = -1;
    days_since_epoch = 0;
    days_per_year = 0;
    seconds_per_year = 0;
    do {
      days_since_epoch += days_per_year;
      time_rfc868 -= seconds_per_year;
      ++time->tm_year;
      days_per_year = DAYS_PER_YEAR;
      is_leap_year = (0 == (time->tm_year % 4)) && (0 != time->tm_year);
      if (is_leap_year) {
        ++days_per_year;
      }
      seconds_per_year = days_per_year * SECONDS_PER_DAY;
    } while (time_rfc868 >= seconds_per_year);

    /* Same trick: adjust for previous month, calculate duration of
     * month, see if we're in that month.  Special-case February in leap
     * years.
     */
    days_per_month = 0;
    seconds_per_month = 0;
    time->tm_mon = -1;
    do {
      days_since_epoch += days_per_month;
      time->tm_yday += days_per_month;
      time_rfc868 -= seconds_per_month;
      ++time->tm_mon;
      days_per_month = daysPerMonth[time->tm_mon];
      if (is_leap_year && (MONTH_IDX_FEBRUARY == time->tm_mon)) {
        ++days_per_month;
      }
      seconds_per_month = days_per_month * SECONDS_PER_DAY;
    } while (time_rfc868 >= seconds_per_month);

    /* Loop with subtraction rather than divide/modulus because this
     * goes on an embedded device and code size is smaller this way.
     * This calculation is not time-critical, and the loops are short
     * anyway.
     */
    while (time_rfc868 >= SECONDS_PER_DAY) {
      time_rfc868 -= SECONDS_PER_DAY;
      ++time->tm_mday;
    }

    /* Adjust epoch/year day count then change tm_mday base to be 1 */
    days_since_epoch += time->tm_mday;
    time->tm_yday += time->tm_mday;
    ++time->tm_mday;

    while (time_rfc868 >= SECONDS_PER_HOUR) {
      time_rfc868 -= SECONDS_PER_HOUR;
      ++time->tm_hour;
    }

    while (time_rfc868 >= SECONDS_PER_MINUTE) {
      time_rfc868 -= SECONDS_PER_MINUTE;
      ++time->tm_min;
    }

    time->tm_sec = time_rfc868;
    time->tm_wday = (EPOCH_WDAY + days_since_epoch) % DAYS_PER_WEEK;
    return SUCCESS;
  }

  command uint32_t Rfc868.posixEpochOffset () { return 2208988800UL; }
}
