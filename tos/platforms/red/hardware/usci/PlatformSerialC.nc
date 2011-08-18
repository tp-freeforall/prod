configuration PlatformSerialC {
  provides {
    interface StdControl;
    interface UartStream;
    interface UartByte;
    interface Msp430UsciError;
  }
}
implementation {
  components PlatformSerialP;
  StdControl = PlatformSerialP;

  components new Msp430UsciUartA0C() as UartC;

  UartStream = UartC;
  UartByte = UartC;
  Msp430UsciError = UartC;
  PlatformSerialP.Resource -> UartC.Resource;
}
