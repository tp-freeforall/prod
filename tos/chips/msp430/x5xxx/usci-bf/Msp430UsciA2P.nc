/* DO NOT MODIFY
 * This file cloned from Msp430UsciA0P.nc for A2 */
/** A non-generic instance of Msp430UsciC for USCI_A2. */
configuration Msp430UsciA2P {
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

  components new HplMsp430UsciC(UCA2CTLW0_, MSP430_USCI_A2_RESOURCE) as UsciC;
  USCI  = UsciC;
  Resource = UsciC;
  ResourceRequested = UsciC;
  ResourceDefaultOwner = UsciC;
  ArbiterInfo = UsciC;
  ResourceConfigure = UsciC;
  Interrupts = UsciC;

  components HplMsp430UsciInterruptsA2P as IsrC;
  UsciC.RawInterrupts -> IsrC;
  IsrC.Usci -> UsciC;
}
