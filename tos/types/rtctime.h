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
 *
 * Contact: Eric B. Decker <cire831@gmail.com>
 */

#ifndef __RTCTIME_H__
#define __RTCTIME_H__

/*
 * rtctime_t
 *
 * we use a structure (rtctime_t) that is similar to the Unix tm struct.
 * rtctime is always UTC and includes a sub-second field that typically
 * is 32KiHz jiffies.
 *
 * rtctime matches the msp432 RTC h/w however it should be easy to utilize
 * with other RTC h/w modules..  As we add other RTC h/w, this
 * structure may need to be generalized.  But looks like a reasonable
 * first cut.
 *
 *          tm_struct                   rtctime_t
 * sub_sec  n/a                         sub_sec (msp432, jiffies 1/32768)
 * sec      0..59                       0..59
 * min      0..59                       0..59
 * hr       0..23                       0..23
 * dow             (not used)           0..6    (0 sunday)
 * day      1..31                       1..31
 * wday     0..6   (0 sunday)                   (not used)
 * mon      0..11                       1..12
 * year     signed delta from 1900      actual year
 * yday     0..365                              (not used)
 * isdst    isdst                               (not used)
 */

typedef struct {
  uint16_t sub_sec;                     /* 16 bit jiffies (32KiHz) */
  uint8_t  sec;                         /* 0-59 */
  uint8_t  min;                         /* 0-59 */
  uint8_t  hr;                          /* 0-23 */
  uint8_t  dow;                         /* day of week, 0-6, 0 sunday */
  uint8_t  day;                         /* 1-31 */
  uint8_t  mon;                         /* 1-12 */
  uint16_t year;                        /* actual year */
} rtctime_t;

#endif  /* __RTCTIME_H__ */
