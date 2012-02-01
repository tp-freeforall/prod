
/**
 *
 * 
 **/

configuration FlashTestAppC{
}
implementation
{

  components MainC, FlashTestP, LedsC; 
  //components new TimerMilliC() as Timer0;
  components SerialPrintfC;
  
  FlashTestP -> MainC.Boot;
  FlashTestP.Leds -> LedsC;
  
  components new SettingsC();
  FlashTestP.Settings -> SettingsC;
  
  components SettingsP;
  FlashTestP.Init -> SettingsP;
  
  components Msp430FlashC;
  FlashTestP.Msp430Flash -> Msp430FlashC.Msp430Flash;
  
  components ClientC;
 }
