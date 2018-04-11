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
   * @return SUCCESS normally; EINVAL if the time pointer is null or
   * the referenced structure does not represent a valid time;
   */
  async command error_t setTime(rtctime_t *timep);


  /**
   * getTime
   *
   * get current time.  non split-phase
   */
  async command error_t getTime(rtctime_t *timep);


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
   * Request current time be provided at next second boundary.
   *
   * A split phase request for the time.
   *
   * Since reading clock registers is not an atomic action for some
   * clocks, and the instability period can be long (~4ms on MSP432p401R),
   * rather than potentially delay or return an error, invoking this
   * function will cause a currentTime() event to be raised the next
   * time the clock is updated, possibly during the execution of this
   * function.  Consequently, the returned time will not be the exact
   * "current time", but rather the time at which the next
   * calendar-second rollover event completes.
   *
   * @param event_code An event code from RtcTimeEventReason_t enums
   * that will be included in the notification event set.  Pass zero
   * (RTC_REASON_NONE) if you don't need to distinguish this particular
   * event (just yield the next second rollover).
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
  async command error_t requestTime(uint32_t event_code);


  /**
   * Notification of a time event completion.
   *
   * This event is synchronous with completion of a roll-over to a
   * specific time.  That is, all events associated with a specific
   * time should be reflected in the reason_set.
   *
   * @param timep Pointer to the time of the event.  This is allocated
   * on the stack of the event signaller.  The receiptent should either
   * immediately use the time or copy it to a more permanent location.
   *
   * @param reason_set Bits are set to values from the enum
   * RtcTimeEventReason_t to indicate what caused this event to fire.
   *
   * Examples are RTC_REASON_EVENT, RTC_REASON_ALARM, and anything
   * provided by invoking requestTime().
   */
  async event void currentTime(rtctime_t *timep, uint32_t reason_set);


  /**
   * Configure specific rtc events.
   *
   * Prior to reconfiguring, any current event is disabled,
   * meaning that if you provide an invalid argument, your previous
   * configuration gets wiped.
   *
   * @param event_mode the type of event that should be signaled
   *
   * @return SUCCESS if the event is scheduled; EINVAL if the mode is
   * not supported on this hardware.
   */
  async command error_t setEventMode(RtcEvent_t event_mode);


  /** Read the current rtc event mode. */
  async command RtcEvent_t getEventMode();


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
   * @param time Where the alarm values should be stored.  If
   * provided, all relevant alarm fields are stored, even if they
   * are not part of the field set.
   *
   * @return A bit set comprising values from RtcAlarmField_t
   * indicating which fields are part of the alarm.  A return value
   * of zero indicates that no alarm is scheduled.
   */
  async command uint32_t getAlarm(rtctime_t *timep);
}
