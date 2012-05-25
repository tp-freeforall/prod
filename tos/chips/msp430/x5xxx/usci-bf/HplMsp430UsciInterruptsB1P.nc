/* DO NOT MODIFY
 * This file cloned from HplMsp430UsciInterruptsA0P.nc for B1 */
/**
 * Define the interrupt handlers for USCI module B1.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

module HplMsp430UsciInterruptsB1P {
  provides interface HplMsp430UsciInterrupts as Interrupts;
  uses {
    interface HplMsp430Usci as Usci;
    interface Leds;
  }
}
implementation {
  TOSH_SIGNAL(USCI_B1_VECTOR) {
    signal Interrupts.interrupted((call Usci.getIv()));
  }
}
