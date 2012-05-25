/* DO NOT MODIFY
 * This file cloned from Msp430UsciA0P.nc for B1 */
/** A non-generic instance of Msp430UsciC for USCI_B1. */
configuration Msp430UsciB1P {
  provides {
    interface HplMsp430Usci as USCI;
    interface Resource[uint8_t client];
    interface ResourceRequested[uint8_t client];
    interface ResourceDefaultOwner;
    interface ArbiterInfo;
    interface HplMsp430UsciInterrupts as Interrupts[uint8_t mode];
  }
  uses interface ResourceConfigure[uint8_t client];
}
implementation {

  components new HplMsp430UsciC(UCB1CTLW0_, MSP430_USCI_B1_RESOURCE) as UsciC;
  USCI  = UsciC;
  Resource = UsciC;
  ResourceRequested = UsciC;
  ResourceDefaultOwner = UsciC;
  ArbiterInfo = UsciC;
  ResourceConfigure = UsciC;
  Interrupts = UsciC;

  components HplMsp430UsciInterruptsB1P as IsrC;
  UsciC.RawInterrupts -> IsrC;
  IsrC.Usci -> UsciC;
}
