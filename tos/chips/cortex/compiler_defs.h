/*
 * define various things that the compiler makes available.
 *
 * noinit:      do not initilize this variable
 * NOINIT:      do not initilize this variable
 * PACKED:      cancel any alignment restrictions.
 * NOP/nop      nop instructions
 * BKPT/bkpt    breakpoint instructions
 */

#ifndef __COMPILER_DEFS_H__
#define __COMPILER_DEFS_H__

#ifdef __GNUC__
// GCC tool chain, define PACKED and noint

#ifndef PACKED
#define PACKED __attribute__((__packed__))
#endif

#ifndef noinit
#define noinit	__attribute__ ((section(".noinit")))
#endif

#ifndef NOINIT
#define NOINIT	__attribute__ ((section(".noinit")))
#endif

/*
 * The msp432 uses CMSIS 4 (core_cm4.h) which defines __NOP as static inline
 * function, which is great, but it confuses gdb into thinking that the
 * nop is a function and its source is in the cmsis_gcc.h file.
 *
 * But we want to be able to insert nops into optimized code so we can set
 * breaks on them.  The way to do this is make the __nop a define.
 */
#ifndef nop
#define nop()     __asm volatile ("nop")
#endif
#ifndef bkpt
#define bkpt(val) __asm volatile ("bkpt "#val)
#endif

/*
 * The Sam3 uses a Cortex-M3 and the CMSIS installed for it is really old.
 * Further the Sam3 has a real problem with an include nightmare.  It
 * should be updated to CMSIS 4 or greater but is only worth it if
 * someone will actively use it.  Otherwise not worth the effort.  In
 * the meantime, the following cludge takes care of the immediate need.
 *
 * Only define __NEED_BKPT__ or __NEED_NOP__ if you really need to
 * use them because you are using the old CMSIS 1 stuff.  Any new
 * Cortex processors should be using modern CMSIS and won't need
 * to define them.
 *
 * If this ever gets cleaned up, these should get removed.  Dependent on
 * the old Sam3 code.
 */
#ifdef __NEED_BKPT__
#define __BKPT(value) __asm volatile ("bkpt "#value)
#endif
#ifdef __NEED_NOP__
#define __NOP()       __asm volatile ("nop")
#endif

#else
#warning non-GCC toolchain.  may not work correctly
#endif


// return aligned address, a, to lower multiple of n
#define ALIGN_N(a, n)                                           \
({                                                              \
        uint32_t __a = (uint32_t) (a);                          \
        (typeof(a)) (__a - __a % (n));                          \
})

#ifdef notdef
// Not used, remove
// Round up to the nearest multiple of n
#define ROUNDUP(a, n)                                           \
({                                                              \
        uint32_t __n = (uint32_t) (n);                          \
        (typeof(a)) (ALIGN_N((uint32_t) (a) + __n - 1, __n)); \
})
#endif

#endif /* __COMPILER_DEFS_H__ */
