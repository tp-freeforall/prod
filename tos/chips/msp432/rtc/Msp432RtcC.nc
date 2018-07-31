configuration Msp432RtcC {
  provides {
    interface Rtc;
    interface RtcAlarm;
    interface RtcEvent;
  }
  uses     interface RtcHWInterrupt;
}
implementation {
  components Msp432RtcP;
  Rtc            = Msp432RtcP;
  RtcAlarm       = Msp432RtcP;
  RtcEvent       = Msp432RtcP;
  RtcHWInterrupt = Msp432RtcP;

  components PanicC;
  Msp432RtcP.Panic -> PanicC;
}
