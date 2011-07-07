
#ifndef EWMA_H
#define EWMA_H

/**
 * The size of each squelch table
 */
#ifndef EWMA_TABLE_SIZE
#define EWMA_TABLE_SIZE 10
#endif

/**
 * Minimum number of measurements before being settled
 */
#ifndef EWMA_MIN_COUNT
#define EWMA_MIN_COUNT 20
#endif

/**
 * Initial squelch threshold
 */
#ifndef EWMA_INITIAL_THRESHOLD
#define EWMA_INITIAL_THRESHOLD 70U
#endif

/**
 * Scaling numerator
 */
#ifndef EWMA_NUMERATOR
#define EWMA_NUMERATOR 19
#endif

/**
 * Scaling denominator
 */
#ifndef EWMA_DENOMINATOR
#define EWMA_DENOMINATOR 20
#endif


/**
 * Unique identifier for squelch clients
 */
#ifndef UQ_EWMA_CLIENT
#define UQ_EWMA_CLIENT "Unique.Squelch.Client"
#endif


#endif

