configuration Msp430UsciUartA0P {
  provides {
    interface UartStream[uint8_t client];
    interface UartByte[uint8_t client];
    interface ResourceConfigure[uint8_t client];
    interface Msp430UsciError[uint8_t client];
  }
  uses {
    interface Msp430UsciConfigure[ uint8_t client ];
    interface HplMsp430GeneralIO as URXD;
    interface HplMsp430GeneralIO as UTXD;
  }
} implementation {

  components Msp430UsciA0P as UsciC;
  //masks are module-specific so they need to be passed in.
  //alternately, the masks could be retrieved from the UsciA interface
  components new Msp430UsciUartP(UCA0TXIE, UCA0RXIE, UCA0TXIFG, UCA0RXIFG) as UartC;

  UartC.Usci -> UsciC;
  UartC.UsciA -> UsciC;
  UartC.RXInterrupts -> UsciC.RXInterrupts[MSP430_USCI_UART];
  UartC.TXInterrupts -> UsciC.TXInterrupts[MSP430_USCI_UART];
  UartC.StateInterrupts -> UsciC.StateInterrupts[MSP430_USCI_UART];
  UartC.ArbiterInfo -> UsciC;

  Msp430UsciConfigure = UartC;
  ResourceConfigure = UartC;
  UartStream = UartC;
  UartByte = UartC;
  Msp430UsciError = UartC;
  URXD = UartC.URXD;
  UTXD = UartC.UTXD;

  components LocalTimeMilliC;
  UartC.LocalTime_bms -> LocalTimeMilliC;

}
