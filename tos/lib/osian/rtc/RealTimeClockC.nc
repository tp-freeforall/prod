configuration RealTimeClockC {
  provides {
    interface StdControl;
    interface RealTimeClock;
    interface Rfc868;
  }
} implementation {
  components PlatformRealTimeClockC;
  StdControl = PlatformRealTimeClockC;
  RealTimeClock = PlatformRealTimeClockC;

  components Rfc868P;
  Rfc868 = Rfc868P;
}
