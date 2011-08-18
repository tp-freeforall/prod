/**
 * Define the interrupt handlers for USCI module A0.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

module HplMsp430UsciInterruptsA0P {
  provides interface HplMsp430UsciInterrupts as Interrupts;
  uses {
    interface HplMsp430Usci as Usci;
    interface Leds;
  }
}
implementation {
  TOSH_SIGNAL(USCI_A0_VECTOR) {
    signal Interrupts.interrupted((call Usci.getIv()));
  }
}
