configuration Msp432RtcC {
  provides interface Rtc;
}
implementation {
  components Msp432RtcP;
  Rtc = Msp432RtcP;

  components PanicC;
  Msp432RtcP.Panic -> PanicC;
}
