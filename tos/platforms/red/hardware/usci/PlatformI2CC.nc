configuration PlatformI2CC {
  provides {
    interface StdControl;
    interface I2CPacket<TI2CBasicAddr>;
    interface Msp430UsciError;
  }
}
implementation {
  components PlatformI2CP;
  StdControl = PlatformI2CP;

  components new Msp430UsciI2CB0C() as I2CC;

  I2CPacket = I2CC;
  Msp430UsciError = I2CC;
  PlatformI2CP.Resource -> I2CC.Resource;
}
