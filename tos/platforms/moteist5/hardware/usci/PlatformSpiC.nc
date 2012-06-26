
configuration PlatformSpiC {
  provides {
    interface SpiByte;
    interface Resource;
    interface SpiPacket;
    interface Msp430UsciError;
  }
}

implementation {
  
  components PlatformSpiP;

  components new Msp430UsciSpiB0C() as SpiC;

  SpiByte = SpiC;
  Resource = SpiC;
  SpiPacket = SpiC;

  Msp430UsciError = SpiC;
  PlatformSpiP.Resource -> SpiC.Resource;
  
}
