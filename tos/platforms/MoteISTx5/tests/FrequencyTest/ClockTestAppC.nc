
/**
 * This app is to test the MCLK frequency change, configure pins in booted event
 * @author João Gonçalves <joao.m.goncalves@ist.utl.pt>
 **/

configuration ClockTestAppC{
}
implementation
{

  components MainC, ClockTestP, LedsC;
  //components new TimerMilliC() as Timer0;
  components SerialPrintfC;
  //components PlatformSerialC;
  //ClockTestP.UartByte -> PlatformSerialC;
  
  components Msp430FreqControlC;
  ClockTestP.FreqControl -> Msp430FreqControlC;

  ClockTestP -> MainC.Boot;
  //ClockTestP.Timer0 -> Timer0;
  ClockTestP.Leds -> LedsC;
}

