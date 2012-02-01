
/**
 * This app is to test the MCLK frequency change, configure pins in booted event
 * @author João Gonçalves <joao.m.goncalves@ist.utl.pt>
 **/

configuration PrintfAppC{
}
implementation
{
  components MainC, PrintfP, LedsC; 
  components SerialPrintfC;
  //components PlatformSerialC;
  //ClockTestP.UartByte -> PlatformSerialC;
  
  PrintfP -> MainC.Boot;
  PrintfP.Leds -> LedsC;
}

