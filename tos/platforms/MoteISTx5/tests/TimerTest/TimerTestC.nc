
#include <Timer.h>

configuration TimerTestC {
}
implementation {
  components MainC;
  components LedsC;
  components TimerTestP as App;
  components new TimerMilliC() as Timer0;
  components SerialPrintfC;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Timer0 -> Timer0;

}
