/* DO NOT MODIFY
 * This file cloned from Msp430UsciSpiB0P.nc for A2 */
configuration Msp430UsciSpiA2P {
  provides {
    interface SpiPacket[ uint8_t client ];
    interface SpiBlock;
    interface SpiByte;
    interface Msp430UsciError;
    interface ResourceConfigure[ uint8_t client ];
  }
  uses {
    interface Msp430UsciConfigure[ uint8_t client ];
    interface HplMsp430GeneralIO as SIMO;
    interface HplMsp430GeneralIO as SOMI;
    interface HplMsp430GeneralIO as CLK;
 }
}
implementation {

  components Msp430UsciA2P as UsciC;

  components new Msp430UsciSpiP() as SpiC;
  SpiC.Usci -> UsciC;
  SpiC.Interrupts -> UsciC.Interrupts[MSP430_USCI_SPI];
  SpiC.ArbiterInfo -> UsciC;

  Msp430UsciConfigure = SpiC;
  ResourceConfigure = SpiC;
  SpiPacket = SpiC;
  SpiBlock  = SpiC;
  SpiByte   = SpiC;
  Msp430UsciError = SpiC;
  SIMO = SpiC.SIMO;
  SOMI = SpiC.SOMI;
  CLK = SpiC.CLK;
}
