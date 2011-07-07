configuration Ucs7WorkaroundC {
  provides {
    interface StdControl as InhibitUcs7WorkaroundControl;
  }
} implementation {
  components Ucs7WorkaroundP;
  InhibitUcs7WorkaroundControl = Ucs7WorkaroundP;

  components MainC;
  MainC.SoftwareInit -> Ucs7WorkaroundP;

  components Msp430XV2ClockC;
  Ucs7WorkaroundP.InhibitUcs7WorkaroundLowerControl -> Msp430XV2ClockC;

  components new MuxAlarm32khz16C();
  Ucs7WorkaroundP.Alarm32khz16 -> MuxAlarm32khz16C;

  components McuSleepC;
  Ucs7WorkaroundP.McuSleepEvents -> McuSleepC;
  McuSleepC.McuPowerOverride -> Ucs7WorkaroundP;
}
