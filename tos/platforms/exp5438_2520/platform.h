
#ifndef _H_PLATFORM_H_
#define _H_PLATFORM_H_

#define REQUIRE_PANIC
#define REQUIRE_PLATFORM
#define FORCE_ATOMIC
#define TRACE_MICRO
//#define TRACE_USE_PLATFORM

/*
 * The msp430 LocalTimeMicro implementation by default uses LocalTimeHybridMicro
 * implementation which is very expensive and busy waits on the 32Khz timer.
 *
 * We don't want this.
 */
#define DISABLE_HYBRID_MICRO

/*
 * mm5s uses a msp430f5438a and when we use -Os h/w access (mem mapped i/o)
 * occurs using single instructions.  So we turn on various port access
 * optimizations if we are compiling using -Os.
 *
 * Well __OPTIMIZE_SIZE__ is supposed to be defined if -Os is specified and
 * looking at stuff with -dM -E seems to say it is defined, but for some
 * reason it doesn't seem to work when we actually try to use it.
 *
 * FORCE_ATOMIC exists to allow overriding.
 */

#if defined(__OPTIMIZE_SIZE__) || defined(FORCE_ATOMIC)
#warning Using low level non-atomic register access
#define MSP430_PINS_ATOMIC_LOWLEVEL
#define MSP430_USCI_ATOMIC_LOWLEVEL
#endif

#endif  /* _H_PLATFORM_H_ */
