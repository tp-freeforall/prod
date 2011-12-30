
configuration BusyMicroTestC {}
implementation {

  components MainC, BusyMicroTestP as App, LedsC;
  App.Boot -> MainC.Boot;
  App.Leds -> LedsC;

  components new TimerMilliC() as Timer;
  App.Timer -> Timer;

  components BusyWaitMicroC;
  App.BusyWait -> BusyWaitMicroC;

  components HplMsp430GeneralIOC as GeneralIOC;    
  components new Msp430GpioC() as SCLKM;
  SCLKM  -> GeneralIOC.Port26;
  App.SCLK -> SCLKM;
}
