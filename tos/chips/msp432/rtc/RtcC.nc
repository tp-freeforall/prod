configuration RtcC {
  provides interface Rtc;
}
implementation {
  components RtcP;
  Rtc = RtcP;

  components PanicC;
  RtcP.Panic -> PanicC;
}
