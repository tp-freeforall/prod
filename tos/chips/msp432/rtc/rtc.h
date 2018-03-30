#ifndef __RTC_H__
#define __RTC_H__

/**
 * RTC events
 *
 * The MSP432 RTC h/w provides event signalling for minute,
 * hour, noon, and midnight wrap.
 */

typedef enum RtcEvent_e {
  RTC_EVENT_NONE = 0,                   /* next second    */
  RTC_EVENT_MIN,                        /* minute changed */
  RTC_EVENT_HOUR,                       /* hour   changed */
  RTC_EVENT_1200,                       /* noon           */
  RTC_EVENT_0000,                       /* midnight       */
} RtcEvent_t;

/**
 * RtcTimeEventReason_t
 *
 * passed to requestTime and returned by currentTime.
 * Reasons why a currentTime event was signalled
 */
typedef enum RtcTimeEventReason_e {
  RTC_REASON_NONE  = 0x00,              /* none, second bndry */
  RTC_REASON_EVENT = 0x01,              /* event, see above   */
  RTC_REASON_ALARM = 0x02,              /* alarm              */
  RTC_REASON_USER1 = 0x10,              /* user 1             */
  RTC_REASON_USER2 = 0x20,              /* user 2             */
  RTC_REASON_USER3 = 0x40,              /* user 3             */
  RTC_REASON_USER4 = 0x80,              /* user 4             */
} RtcTimeEventReason_t;

/**
 * Fields for setting alarm events.  All enabled fields must match
 * the set value for the event to fire.
 */
typedef enum RtcAlarmField_e {
  RTC_ALARM_MINUTE = 0x01,              /* match on minute */
  RTC_ALARM_HOUR   = 0x02,              /* match on hour   */
  RTC_ALARM_DOW    = 0x04,              /* match on dow    */
  RTC_ALARM_DOM    = 0x08,              /* match on dom    */
  RTC_ALARM_MON    = 0x10,              /* match on month  */
  RTC_ALARM_YEAR   = 0x20,              /* match on year   */
} RtcAlarmField_t;

#endif /* __RTC_H__ */
