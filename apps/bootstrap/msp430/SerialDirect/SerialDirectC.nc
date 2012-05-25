
#include "msp430usci.h"

configuration SerialDirectC {}
implementation {
  components SerialDirectP as App, MainC;
  App.Boot -> MainC.Boot;

#ifdef USE_X1
#warning USE_X1: building for x1 msp430
  components HplMsp430Usart0C as Port;
#elif USE_X2
#warning USE_X2: building for x2 msp430
  components HplMsp430UsciA0C as Port;
#elif USE_X5
#warning USE_X5: building for x5 msp430
  components new HplMsp430UsciC(UCA1CTLW0_, MSP430_USCI_A1_RESOURCE) as Port;
  components HplMsp430UsciInterruptsA1P as PortInt;
#else
#error USE_<X> not defined, X needs to be X1, X2, or X5
#endif

  App.Port -> Port;
  App.PortInt -> PortInt;
  PortInt.Usci -> Port;
}
