/*
 * panic codes.
 */


#ifndef __PLATFORM_PANIC_H__
#define __PLATFORM_PANIC_H__

#include "panic.h"

/*
 * KERN:	core kernal  (in panic.h)
 * ADC:		Analog Digital Conversion subsystem (AdcP.nc)
 * MISC:
 * COMM:	communications subsystem
 */

#ifdef notdef
enum {
  __pcode_timing = PANIC_HC_START,		/* 0x10, see panic.h */
  __pcode_adc,
  __pcode_misc,
  __pcode_comm,
};

#define PANIC_TIMING __pcode_timing
#define PANIC_ADC    __pcode_adc
#define PANIC_MISC   __pcode_misc
#define PANIC_COMM   __pcode_comm

#endif

#endif /* __PLATFORM_PANIC_H__ */
