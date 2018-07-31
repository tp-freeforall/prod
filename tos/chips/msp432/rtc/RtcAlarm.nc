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

interface RtcAlarm {
  /**
   * Set the alarm to occur at a particular time.
   *
   * The time of the alarm is mediated by a set of bits that indicate
   * which time fields contribute to the alarm scheduling.  For
   * example, setting an alarm for 10:23am with field RTC_ALARM_MIN
   * set but RTC_ALARM_HOUR clear would initiate an alarm at 23
   * minutes after every hour, not just 10am.
   *
   * @param time The time at which the alarm should occur.  Only those
   * fields that are specified in field_set affect the alarm schedule.
   * Pass a null pointer to disable the alarm.
   *
   * @param field_set A bit set comprising values from RtcAlarmField_t
   * indicating which fields affect the alarm.  Some field conditions
   * may not be supported on some RTC hardware; in that case, the
   * request should be rejected with an error.
   *
   * @return SUCCESS if the alarm was properly scheduled; EINVAL if
   * the field_set specifies an unsupported field.  The alarm is
   * cleared if this function does not return SUCCESS.
   */
  async command error_t setAlarm(rtctime_t *timep, uint32_t field_set);


  /**
   * Read the current alarm.
   *
   * @param timepp where to stick a pointer to the current alarm setting.
   *
   * @return A bit set (array) comprising values from RtcAlarmField_t
   * indicating which fields are part of the alarm.  A return value
   * of zero indicates that no alarm is scheduled.
   */
  async command uint32_t getAlarm(rtctime_t **timepp);


  /**
   * Notification of a rtcAlarm.
   *
   * The requested alarm has triggered.
   *
   * @param timep:      pointer to the current time.
   * @param field_set:  original requested field_set.
   */
  async event void rtcAlarm(rtctime_t *timep, uint32_t field_set);
}
