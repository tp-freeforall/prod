/** A non-generic instance of Msp430UsciC for USCI_A0. */
configuration Msp430UsciB0P {
  provides {
    interface HplMsp430Usci as USCI;
    interface HplMsp430UsciB as USCIB;
    interface Resource[uint8_t client];
    interface ResourceRequested[uint8_t client];
    interface ResourceDefaultOwner;
    interface ArbiterInfo;
    interface HplMsp430UsciInterrupts as RXInterrupts[uint8_t mode];
    interface HplMsp430UsciInterrupts as TXInterrupts[uint8_t mode];
    interface HplMsp430UsciInterrupts as StateInterrupts[uint8_t mode];
  }
  uses {
    interface ResourceConfigure[uint8_t client];
 }

} implementation {
  components new HplMsp430UsciBC(UCB0CTL0_, 
    IE2_, 
    UCB0I2COA_,
    MSP430_USCI_B0_RESOURCE) as UsciC;
  USCI  = UsciC;
  USCIB = UsciC;
  Resource = UsciC;
  ResourceRequested = UsciC;
  ResourceDefaultOwner = UsciC;
  ArbiterInfo = UsciC;
  ResourceConfigure = UsciC;
  RXInterrupts = UsciC.RXInterrupts;
  TXInterrupts = UsciC.TXInterrupts;
  StateInterrupts = UsciC.StateInterrupts;

  components HplMsp430UsciInterruptsAB0P as IsrC;
  UsciC.RawRXInterrupts -> IsrC.InterruptsUCB0Rx;
  UsciC.RawTXInterrupts -> IsrC.InterruptsUCB0Tx;
  UsciC.RawStateInterrupts -> IsrC.InterruptsUCB0State;
}

