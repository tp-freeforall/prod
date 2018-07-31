#ifndef __RTC_H__
#define __RTC_H__

/**
 * RTC events
 *
 * The MSP432 RTC h/w provides event signalling for minute,
 * hour, noon, and midnight wrap.  We add sec.
 */

typedef enum {
  RTC_EVENT_NONE = 0,                   /* no event       */
  RTC_EVENT_SEC,                        /* next second    */
  RTC_EVENT_MIN,                        /* minute changed */
  RTC_EVENT_HOUR,                       /* hour   changed */
  RTC_EVENT_0000,                       /* midnight       */
  RTC_EVENT_1200,                       /* noon           */
} rtcevent_t;


/**
 * Fields for setting alarm events.  All enabled fields must match
 * the set value for the event to fire.
 */
typedef enum {
  RTC_ALARM_MINUTE = 0x01,              /* match on minute */
  RTC_ALARM_HOUR   = 0x02,              /* match on hour   */
  RTC_ALARM_DOW    = 0x04,              /* match on dow    */
  RTC_ALARM_DAY    = 0x08,              /* match on day    */
  RTC_ALARM_MON    = 0x10,              /* match on month  */
  RTC_ALARM_YEAR   = 0x20,              /* match on year   */
} rtcalarm_t;

#endif /* __RTC_H__ */
