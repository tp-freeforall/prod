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

/** Interface to a real-time clock.
 *
 * This interface assumes hardware support for a calendar-based clock
 * including date and time, with nominally one-second resolution.
 * Events and operations on this clock are assumed to be synchronous
 * with these date/time changes.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

interface RealTimeClock {

  /** Set the local time.
   *
   * The clock must be running.
   *
   * @return SUCCESS normally; EINVAL if the time pointer is null or
   * the referenced structure does not represent a valid time; EOFF if
   * the clock is not running.
   */
  command error_t setTime (const struct tm* time);

  /** Request that the current time be provided.
   *
   * Since reading clock registers is not an atomic action for some
   * clocks, and the instability period can be long (3ms on MSP430),
   * rather than potentially delay or return an error, invoking this
   * function will cause a currentTime() event to be raised the next
   * time the clock is updated, possibly during the execution of this
   * function.  Consequently, the returned time will not be the exact
   * "current time", but rather the time at which the next
   * calendar-second rollover event completes.
   *
   * @param event_code An event bit from RtcTimeEventReason_b that
   * will be included in the notification event set.  Pass zero if you
   * don't need to distinguish this particular event.
   *
   * @note The delay until a valid time is provided may be up to one
   * second.
   *
   * @note A 1Hz or coarser event synchronous with clock rollovers can
   * be obtained by using a standard timer and invoking this method in
   * its notification event, providing one of the RTC_REASON_USER
   * codes.
   *
   * @return SUCCESS, probably.
   */
  command error_t requestTime (unsigned int event_code);

  /** Configure events at a periodic real-time interval.
   *
   * Prior to reconfiguring, any current interval event is disabled,
   * meaning that if you provide an invalid argument, your previous
   * configuration gets wiped.
   *
   * @param interval_mode the type of interval for which events should
   * be signaled
   *
   * @return SUCCESS if the event is scheduled; EINVAL if the mode is
   * not supported on this hardware.
   */
  command error_t setIntervalMode (RtcIntervalMode_e interval_mode);

  /** Read the current periodic event interval mode. */
  command RtcIntervalMode_e getIntervalMode ();

  /** Set the alarm to occur at a particular time.
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
   * @param field_set A bit set comprising values from RtcAlarmField_b
   * indicating which fields affect the alarm.  Some field conditions
   * may not be supported on some RTC hardware; in that case, the
   * request should be rejected with an error.
   *
   * @return SUCCESS if the alarm was properly scheduled; EINVAL if
   * the field_set specifies an unsupported field.  The alarm is
   * cleared if this function does not return SUCCESS.
   */
  command error_t setAlarm (const struct tm* time,
                            unsigned int field_set);

  /** Read the current alarm setting.
   *
   * @param time Where the alarm values should be stored.  If
   * provided, all relevant alarm fields are stored, even if they are
   * not part of the field set.
   *
   * @return A bit set comprising values from RtcAlarmField_b
   * indicating which fields are part of the alarm.  A return value of
   * zero indicates that no alarm is scheduled.
   */
  command unsigned int getAlarm (struct tm* time);

  /** Notification of the time of an activity.
   *
   * This event is synchronous with completion of a roll-over to a
   * specific time.  That is, all events associated with a specific
   * time should be reflected in the reason_set.
   *
   * @param timep Pointer to the time of the event.
   *
   * @param reason_set Bits are set to fields from
   * RtcTimeEventReason_b to indicate what caused this event to fire.
   * Examples are RTC_REASON_INTERVAL, RTC_REASON_ALARM, and anything
   * provided by invoking requestTime().
   */
  async event void currentTime (const struct tm* timep,
                                unsigned int reason_set);
}
