/* DO NOT MODIFY
 * This file cloned from HplMsp430UsciInterruptsA0P.nc for A2 */
/**
 * Define the interrupt handlers for USCI module A2.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

module HplMsp430UsciInterruptsA2P {
  provides interface HplMsp430UsciInterrupts as Interrupts;
  uses {
    interface HplMsp430Usci as Usci;
    interface Leds;
  }
}
implementation {
  TOSH_SIGNAL(USCI_A2_VECTOR) {
    signal Interrupts.interrupted((call Usci.getIv()));
  }
}
