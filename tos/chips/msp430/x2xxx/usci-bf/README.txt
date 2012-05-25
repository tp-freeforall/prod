This directory contains the USCI implementation for the first
generation USCI module (from Peter Bigot/People Power's explanation):

There are at least three USCI implementations supported over the
MSP430 family.  The implementations are distinguished by the functional
presence preproprocessor macro as defined in the TI standard headers from
Code Composer Studio distribution:

*__MSP430_HAS_USCI__ -- indicates the original USCI implementation on chips:
     msp430x21x2 msp430x22x2 msp430x22x4 msp430x23x msp430x23x0 msp430x241x
     msp430x24x msp430x24x1 msp430x26x msp430x41x2 msp430x471x6 msp430x471x7
     msp430x47x msp430x47x3 msp430x47x4 msp430xG46x msp430xG47x

 __MSP430_HAS_USCI_AB0__ -- second generation USCI implementation on chips:
     msp430x241x msp430x24x msp430x24x1 msp430x26x msp430x471x6 msp430x471x7
     msp430x47x3 msp430x47x4 msp430x241x msp430x24x msp430x24x1 msp430x26x
     msp430x471x6 msp430x471x7 msp430x47x3 msp430x47x4

 __MSP430_HAS_USCI_A0__, __MSP430_HAS_USCI_B0__ -- third generation USCI
   implementation on chips:
     cc430x513x cc430x612x cc430x613x msp430x54x msp430x54xA msp430x551x
     msp430x552x

Some characteristics of note:

USCI A0/A1 offsets (UART/SPI)
=============================
Control registers
-----------------
-0x03 UCA0ABCTL  
-0x02 UCA0IRTCTL 
-0x01 UCAxIRRCTL
 0x00 UCAxCTL0
 0x01 UCAxCTL1
 0x02 UCAxBR0
 0x03 UCAxBR1
 0x04 UCAxMCTL
 0x05 UCAxSTAT
 0x06 UCAxRXBUF
 0x07 UCAxTXBUF

Interrupt Registers
-------------------
 0x00 IE  (A0: IE2,  A1: UC1IE)
 0x01 IFG (A0: IFG2, A1: UC1IFG)


USCI B0/B1 offsets (SPI/I2C)
===========================
Control registers
-----------------
 0x00 UCB0CTL0
 0x01 UCB0CTL1
 0x02 UCB0BR0
 0x03 UCB0BR1
 0x04 UCB0I2CIE
 0x05 UCB0STAT
 0x06 UCB0RXBUF
 0x07 UCB0TXBUF

Interrupt Registers
-------------------
  0x00 IE  (B0: IE2, B1: UC1IE)
  0x01 IFG (B0: IFG2, B1: UC1IFG)

I2C address registers
---------------------
  0x00 UCB0I2COA
  0x02 UCB0I2CSA

Notes:
----
@marcus: maybe you got the info about handling the RX interrupt
clearing the RX flag from peter's notes in the cc430's implementation.
I don't see where he got that info from, but he's normally right about
this sort of thing...

tinyos core impl pushes checks for interrupt-pending all the way down
(osian = apply mask to Usci.getIfg).  This is totally generic on
osian because only a single set of masks is defined in the headers
(and used across the modules). e.g. UCTXIFG vs. UCA0TXIFG + UCA1TXIFG.
If we follow the core impl, then the bottom-level usci component can't
be totally generic (c.f. HplMsp430UsciA0P.Usci.isTxIntrPending
HplMsp430UsciA1P.Usci.isTxIntrPending). This will double the ROM
consumption at the bottom for devices with 2 usci A modules, for
instance.
We can't exactly follow the osian approach using JUST the TI headers
(even though they are the same value, we probably shouldn't assume
that you can use UCA0TXIFG and UCA1TXIFG interchangeably).
Encapsulating the differences by using parameters to the generic
module is the way to address this, I think. The non-generic
Msp430UsciUartA0P configuration would instantiate a generic
Msp430UsciUartP module, giving it the set of USCI A0-specific flags
that it needs.  The tradeoff is that masking operations couldn't be
inlined (e.g. would have to look up instance-specific mask to apply)

0 x2xxx compatibility
  - msp430usci.h: switch to mode-union types
  - Top-level "alias" configs
    - Msp430Uart0C -> Msp430UsciUartA0C
    - Msp430Uart1C -> Msp430UsciUartA1C
    - Msp430I2C1C  -> Msp430UsciI2CB0C (?)
    - Msp430I2C2C  -> Msp430UsciI2CB1C (new)
    - Msp430SpiB0C -> Msp430UsciSpiB0C
    - Msp430SpiB1C -> Msp430UsciSpiB1C (new)
  - To match mode-specific config interfaces, change the type
    of interface declared and return the mode-specific member of the
    usci union type. e.g. instead of 
      Msp430UsciConfigure.getConfiguration(){ return &cfg;}
      Msp430UartConfigure.getConfiguration(){ return &(cfg.uartConfig);}
