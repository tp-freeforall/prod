#include "config.h"

configuration TestAppC {
} implementation {
  components TestP;
  components MainC;

  TestP.Boot -> MainC;
  
#if USE_MUX
#define MaybeMuxAlarmC MuxAlarmPrecC
#endif /* USE_MUX */
#if USE_TIMER
#define MaybeMuxAlarmC TimerPrecC
#endif /* USE_TIMER */

#ifndef MaybeMuxAlarmC
#define MaybeMuxAlarmC AlarmPrecC
#endif /* MaybeMuxAlarmC */

#if USE_LEDS
  components LedC;
  TestP.Led0 -> LedC.Led0;
  TestP.Led1 -> LedC.Led1;
  TestP.Led2 -> LedC.Led2;
  TestP.Led3 -> LedC.Led3;
  TestP.Led4 -> LedC.Led4;
  TestP.Led5 -> LedC.Led4;
  TestP.Led6 -> LedC.Led4;
  TestP.Led7 -> LedC.Led4;
#endif /* USE_LEDS */

  components new MaybeMuxAlarmC() as Alarm0C;
  TestP.Alarm0 -> Alarm0C;
#if 1 < ALARM_COUNT
  components new MaybeMuxAlarmC() as Alarm1C;
  TestP.Alarm1 -> Alarm1C;
#if 2 < ALARM_COUNT
  components new MaybeMuxAlarmC() as Alarm2C;
  TestP.Alarm2 -> Alarm2C;
#if 3 < ALARM_COUNT
  components new MaybeMuxAlarmC() as Alarm3C;
  TestP.Alarm3 -> Alarm3C;
#if 4 < ALARM_COUNT
  components new MaybeMuxAlarmC() as Alarm4C;
  TestP.Alarm4 -> Alarm4C;
#if 5 < ALARM_COUNT
  components new MaybeMuxAlarmC() as Alarm5C;
  TestP.Alarm5 -> Alarm5C;
#if 6 < ALARM_COUNT
  components new MaybeMuxAlarmC() as Alarm6C;
  TestP.Alarm6 -> Alarm6C;
#if 7 < ALARM_COUNT
  components new MaybeMuxAlarmC() as Alarm7C;
  TestP.Alarm7 -> Alarm7C;
#endif /* ALARM_COUNT 7 */
#endif /* ALARM_COUNT 6 */
#endif /* ALARM_COUNT 5 */
#endif /* ALARM_COUNT 4 */
#endif /* ALARM_COUNT 3 */
#endif /* ALARM_COUNT 2 */
#endif /* ALARM_COUNT 1 */

  components SerialPrintfC;
}
