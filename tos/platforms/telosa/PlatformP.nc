#include "hardware.h"

/*
 * PlatformP is responsible for initilizing the h/w.
 *
 * HWInit is responsible for h/w reset duing a PUC to support
 * SWReset.  (see below).
 *
 * ClockInit sets up any h/w clocks used to clock the CPU and
 * used for timing.
 *
 * MoteInit and LedsInit finish setting up the h/w.
 *
 * HWInit is responsible for h/w reset after a PUC (power up clear, strange
 * name).  HWInit sets the h/w back to a reasonable known state.  Normally,
 * the system comes up via a POR (power on reset) which resets
 * the ADC h/w.   If the system comes up via a PUC the h/w isn't cleared out
 * which presents problems for example if interrupts are still happening.
 *
 * This is required for SWReset to work properly.  SWReset uses a WatchDog
 * violation to force the reset.   This causes a PUC to occur and we need
 * to clean out the h/w.
 */

module PlatformP @safe() {
  provides interface Init;
  uses interface Init as HWInit;
  uses interface Init as MoteClockInit;
  uses interface Init as MoteInit;
  uses interface Init as LedsInit;
}
implementation {
  command error_t Init.init() {
    call HWInit.init();			/* clean out h/w incase of PUC */
    call MoteClockInit.init();
    call MoteInit.init();
    call LedsInit.init();
    return SUCCESS;
  }

  default command error_t HWInit.init()   { return SUCCESS; }
  default command error_t LedsInit.init() { return SUCCESS; }
}
