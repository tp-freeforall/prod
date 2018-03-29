#ifndef _OSIAN_PLATFORM_SURF_LED_H_
#define _OSIAN_PLATFORM_SURF_LED_H_

/** Constant used in the generic LedC module to determine how many
 * named Led interfaces should be published.  The value should match
 * the size of the table in PlatformLedsP, but we're not going to
 * guess that table's public name. */

#if defined(SURF_REV_BLOCK_A)
#define PLATFORM_LED_COUNT 2
#else
#define PLATFORM_LED_COUNT 5
#endif

#if defined(SURF_REV_A)
#define PLATFORM_LED_BLUE 0
#define PLATFORM_LED_WHITE 1
#define PLATFORM_LED_RED 2
#define PLATFORM_LED_YELLOW 3
#define PLATFORM_LED_GREEN 4

#elif defined(SURF_REV_B)
#define PLATFORM_LED_GREEN 0
#define PLATFORM_LED_RED 1
#if 1 == SURF_REV_B
#define PLATFORM_LED_WHITE 2
#define PLATFORM_LED_ORANGE 3
#else 
#define PLATFORM_LED_ORANGE 2
#define PLATFORM_LED_WHITE 3
#endif
#define PLATFORM_LED_BLUE 4

#elif defined(SURF_REV_BLOCK_A)
#define PLATFORM_LED_GREEN 0
#define PLATFORM_LED_RED 1

#else
#warning Unrecognized SuRF revision: cannot determine LED colors
#endif // SURF_REV_x

#endif // _OSIAN_PLATFORM_SURF_LED_H_
