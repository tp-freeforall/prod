#ifndef _H_hardware_h
#define _H_hardware_h

#include "msp430hardware.h"

// enum so components can override power saving,
// as per TEP 112.
enum {
  TOS_SLEEP_NONE = MSP430_POWER_ACTIVE,
};

/*
 * The cc430f5137 includes the RF1A.   When the radio is being used
 * the PMM VCORE setting must be at or abore 2.
 */

#define RADIO_VCORE_LEVEL 2


#endif // _H_hardware_h
