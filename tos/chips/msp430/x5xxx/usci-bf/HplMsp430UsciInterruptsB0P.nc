/* DO NOT MODIFY
 * This file cloned from HplMsp430UsciInterruptsA0P.nc for B0 */
/**
 * Define the interrupt handlers for USCI module B0.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

module HplMsp430UsciInterruptsB0P {
  provides interface HplMsp430UsciInterrupts as Interrupts;
  uses {
    interface HplMsp430Usci as Usci;
    interface Leds;
  }
}
implementation {
  TOSH_SIGNAL(USCI_B0_VECTOR) {
    signal Interrupts.interrupted((call Usci.getIv()));
  }
}
