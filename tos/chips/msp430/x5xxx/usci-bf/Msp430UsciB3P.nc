/* DO NOT MODIFY
 * This file cloned from Msp430UsciA0P.nc for B3 */
/** A non-generic instance of Msp430UsciC for USCI_B3. */
configuration Msp430UsciB3P {
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

  components new HplMsp430UsciC(UCB3CTLW0_, MSP430_USCI_B3_RESOURCE) as UsciC;
  USCI  = UsciC;
  Resource = UsciC;
  ResourceRequested = UsciC;
  ResourceDefaultOwner = UsciC;
  ArbiterInfo = UsciC;
  ResourceConfigure = UsciC;
  Interrupts = UsciC;

  components HplMsp430UsciInterruptsB3P as IsrC;
  UsciC.RawInterrupts -> IsrC;
  IsrC.Usci -> UsciC;
}
