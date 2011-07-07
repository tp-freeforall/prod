#ifndef _OSIAN_VERSION_H_
#define _OSIAN_VERSION_H_

/* Maintainer note: Prior to a new release, update OSIAN_VERSION_STR,
 * OSIAN_VERSION_MAJOR, OSIAN_VERSION_MINOR, OSIAN_VERSION_PATCHLEVEL
 * in this file, and the contents of ${OSIAN_ROOT}/VERSION to match
 * the value in OSIAN_VERSION_STR. */

/** The version number as a text string */
#define OSIAN_VERSION_STR "1.11.7"

/** First component of version number.  Major changes only, like
 * reimplementing in a different language. */
#define OSIAN_VERSION_MAJOR 1

/** Second component of version number. Significant changes to
 * interfaces and capabilities. */
#define OSIAN_VERSION_MINOR 11

/** Third component of version number.  Incremental improvements, bug
 * fixes */
#define OSIAN_VERSION_PATCHLEVEL 7

/** Translate version number components to an ordinal.  This can be
 * used in preprocessor conditions to support multiple OSIAN releases
 * in one software system, e.g.:
#if OSIAN_VERSION >= OSIAN_VERSION_NUMBER(1,4,3)
// At least version 1.4.3.
#else
// Older than 1.4.3
#endif
*/
#define OSIAN_VERSION_NUMBER(_maj,_min,_pat) ((_pat) + 100 * ((_min) + 100 * (_maj)))

/** The ordinal for this version of OSIAN */
#define OSIAN_VERSION OSIAN_VERSION_NUMBER(OSIAN_VERSION_MAJOR, OSIAN_VERSION_MINOR, OSIAN_VERSION_PATCHLEVEL)

#endif /* _OSIAN_VERSION_H_ */
