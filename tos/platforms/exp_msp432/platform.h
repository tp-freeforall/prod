/* No platform_bootstrap() needed,
 * since memory system doesn't need configuration and
 * the processor mode neither.
 * (see TEP 107)
 */

#ifndef __PLATFORM_H__
#define __PLATFORM_H__

#define REQUIRE_PLATFORM
#define REQUIRE_PANIC

#define IRQ_DEFAULT_PRIORITY    4

#define TRACE_VTIMERS
#define TRACE_TASKS
#define TRACE_TASKS_USECS __platform_usecs_raw()

extern uint32_t __platform_usecs_raw();

/*
 * define PLATFORM_TAn_ASYNC TRUE if the timer is being clocked
 * asyncronously with respect to the main system clock
 */

/*
 * TA0 is Tmicro, clocked by TA0 <- SMCLK/8 <- DCOCLK/2
 * TA1 is Tmilli, clocked by ACLK 32KiHz (async)
 */
#define PLATFORM_TA1_ASYNC TRUE

/* we use 6 bytes from the random number the msp432 provides */
#define PLATFORM_SERIAL_NUM_SIZE 6

#endif // __PLATFORM_H__
