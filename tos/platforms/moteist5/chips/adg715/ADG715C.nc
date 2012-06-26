configuration ADG715C {
  provides interface Init as DefaultInit;
}
implementation{
  
  components ADG715P;
  DefaultInit = ADG715P;
  
  components PlatformI2CC as I2C;
  
  ADG715P.StdControl -> I2C;
  ADG715P.I2CPacket -> I2C;
}
