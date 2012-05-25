/**
 **/

configuration ClockC {
}
implementation {
  components MainC, ClockP, LedsC;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;

  ClockP -> MainC.Boot;

  ClockP.Timer0 -> Timer0;
  ClockP.Timer1 -> Timer1;
  ClockP.Timer2 -> Timer2;
  ClockP.Leds   -> LedsC;
}
