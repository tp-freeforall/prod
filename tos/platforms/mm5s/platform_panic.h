/*
 * panic codes.
 */


#ifndef __PLATFORM_PANIC_H__
#define __PLATFORM_PANIC_H__

#include "panic.h"

/*
 * KERN:	core kernal
 * ADC:		Analog Digital Conversion subsystem (AdcP.nc)
 * MISC:
 * COMM:	communications subsystem
 */

enum {
  PANIC_KERN = PANIC_HC_START,		/* 0x10, see panic.h */
#ifdef notdef
  PANIC_ADC,
  PANIC_MISC,
  PANIC_COMM,
#endif
};

#endif /* __PLATFORM_PANIC_H__ */
