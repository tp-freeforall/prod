/* DO NOT MODIFY
 * This file cloned from Msp430UsciA0P.nc for B2 */
/** A non-generic instance of Msp430UsciC for USCI_B2. */
configuration Msp430UsciB2P {
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

  components new HplMsp430UsciC(UCB2CTLW0_, MSP430_USCI_B2_RESOURCE) as UsciC;
  USCI  = UsciC;
  Resource = UsciC;
  ResourceRequested = UsciC;
  ResourceDefaultOwner = UsciC;
  ArbiterInfo = UsciC;
  ResourceConfigure = UsciC;
  Interrupts = UsciC;

  components HplMsp430UsciInterruptsB2P as IsrC;
  UsciC.RawInterrupts -> IsrC;
  IsrC.Usci -> UsciC;
}
