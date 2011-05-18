#include "hardware.h"

/*
 * PlatformP is responsible for initilizing the h/w.
 *
 * This platform uses a msp430f1611 which uses a WatchDog violation to
 * implement SWReset.  WatchDog causes a PUC (power up clear, strange
 * name) which does NOT reset the h/w back to a known state.
 *
 * SWResetInit is responsible for h/w reset following a PUC.  Normally,
 * the system comes up via a POR (power on reset) which resets the
 * ADC h/w.   If the system comes up via a PUC the h/w isn't cleared out
 * which presents problems for example if interrupts are still happening.
 *
 * This is required for SWReset to work properly.
 *
 * ClockInit sets up any h/w clocks used to clock the CPU and
 * used for timing.
 *
 * MoteInit and LedsInit finish setting up the h/w.
 */

module PlatformP @safe() {
  provides interface Init;
  uses interface Init as SWResetInit;
  uses interface Init as MoteClockInit;
  uses interface Init as MoteInit;
  uses interface Init as LedsInit;
}
implementation {
  command error_t Init.init() {
    call SWResetInit.init();		/* clean out any left overs from PUC */
    call MoteClockInit.init();
    call MoteInit.init();
    call LedsInit.init();
    return SUCCESS;
  }

  default command error_t SWResetInit.init() { return SUCCESS; }
  default command error_t LedsInit.init()    { return SUCCESS; }
}
