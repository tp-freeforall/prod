#ifndef REALTIMECLOCK_H_
#define REALTIMECLOCK_H_

// msp430-libc include files do not define this.

#if ! HAVE_STRUCT_TM
struct tm {
  int tm_sec;         /* seconds */
  int tm_min;         /* minutes */
  int tm_hour;        /* hours */
  int tm_mday;        /* day of the month */
  int tm_mon;         /* month */
  int tm_year;        /* year */
  int tm_wday;        /* day of the week */
  int tm_yday;        /* day in the year */
  int tm_isdst;       /* daylight saving time */
};
#endif /* HAVE_STRUCT_TM */

/** Options for the interval alarm.  These times are expected to be
 * synchronous with the RTC.  A one-second interval that is not so
 * synchronous is not appropriate for this interface.
 */

typedef enum RtcIntervalMode_e {
  /** Interval alarms disabled */
  RTC_INTERVAL_MODE_NONE = 0,
  /** Fires each minute */
  RTC_INTERVAL_MODE_MIN,
  /** Fires each hour */
  RTC_INTERVAL_MODE_HOUR,
  /** Fires at noon */
  RTC_INTERVAL_MODE_1200,
  /** Fires at midnight */
  RTC_INTERVAL_MODE_0000,
} RtcIntervalMode_e;

/** Reasons why a currentTime event was signalled */
typedef enum RtcTimeEventReason_b {
  /** No specific reason (e.g., requestTime() from user) */
  RTC_REASON_NONE = 0x00,
  /** Interval event occurred */
  RTC_REASON_INTERVAL = 0x01,
  /** Alarm event occurred */
  RTC_REASON_ALARM = 0x02,
  /** First user-level event*/
  RTC_REASON_USER1 = 0x10,
  /** Second user-level event*/
  RTC_REASON_USER2 = 0x20,
  /** Third user-level event*/
  RTC_REASON_USER3 = 0x40,
  /** Fourth user-level event*/
  RTC_REASON_USER4 = 0x80,
} RtcTimeEventReason_b;

/** Fields that trigger an alarm event.  All enabled fields must match
 * the set value for the event to fire.
 */
typedef enum RtcAlarmField_b {
  /** Trigger on minute match */
  RTC_ALARM_MINUTE = 0x01,
  /** Trigger on hour match */
  RTC_ALARM_HOUR = 0x02,
  /** Trigger on day-of-week match */
  RTC_ALARM_DOW = 0x04,
  /** Trigger on day-of-month match */
  RTC_ALARM_DOM = 0x08,
} RtcAlarmField_b;

#endif /* REALTIMECLOCK_H_ */
