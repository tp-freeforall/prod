configuration Msp430UsciI2CB0P {
  provides {
    interface I2CPacket<TI2CBasicAddr>[uint8_t client];
    interface I2CSlave[uint8_t client];
    interface ResourceConfigure[uint8_t client];
    interface Msp430UsciError[uint8_t client];
  }
  uses {
    interface Msp430UsciConfigure[ uint8_t client ];
    interface HplMsp430GeneralIO as USCL;
    interface HplMsp430GeneralIO as USDA;
  }
} implementation {

  components Msp430UsciB0P as UsciC;
  //masks are module-specific so they need to be passed in.
  //alternately, the masks could be retrieved from the UsciA interface
  components new Msp430UsciI2CP(UCB0TXIE, UCB0RXIE, UCB0TXIFG, UCB0RXIFG) as I2CC;

  I2CC.Usci -> UsciC;
  I2CC.UsciB -> UsciC;

  I2CC.RXInterrupts -> UsciC.RXInterrupts[MSP430_USCI_I2C];
  I2CC.TXInterrupts -> UsciC.TXInterrupts[MSP430_USCI_I2C];
  I2CC.StateInterrupts -> UsciC.StateInterrupts[MSP430_USCI_I2C];
  I2CC.ArbiterInfo -> UsciC;

  Msp430UsciConfigure = I2CC;
  ResourceConfigure = I2CC;
  I2CPacket = I2CC.I2CBasicAddr;
  I2CSlave = I2CC.I2CSlave;
  Msp430UsciError = I2CC;
  USCL = I2CC.SCL;
  USDA = I2CC.SDA;

  components LocalTimeMilliC;
  I2CC.LocalTime_bms -> LocalTimeMilliC;
}
