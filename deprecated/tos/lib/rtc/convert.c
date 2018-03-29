#include <stdio.h>
#include <stdint.h>
#include <time.h>
#include <limits.h>
#include <string.h>

enum {
  SECONDS_PER_MINUTE = 60,
  SECONDS_PER_HOUR = 60 * SECONDS_PER_MINUTE,
  SECONDS_PER_DAY = 24 * SECONDS_PER_HOUR,
  /** RFC868 epoch is 1900-01-01T00:00:00Z which was a Monday */
  EPOCH_WDAY = 1,
  DAYS_PER_WEEK = 7,
  DAYS_PER_YEAR = 365,
  MONTH_IDX_FEBRUARY = 1,
};

static const uint8_t daysPerMonth[] = { 31, 28, 31, 30, 31, 30,
                                        31, 31, 30, 31, 30, 31 };

/** Convert an RFC868 time (seconds since 1900-01-01T00:00:00Z) into a
 * POSIX tm structure, including correct values for day-of-week and
 * day-of-year
 */

static const struct tm*
rfc868ToStruct (uint32_t time_sec) {
  static struct tm time_tm;
  int is_leap_year;
  unsigned int days_since_epoch;
  int days_per_year;
  long int seconds_per_year;
  int days_per_month;
  long int seconds_per_month;

  memset(&time_tm, 0, sizeof(time_tm));

  /* To simplify the loop, we adjust for the previous year before
   * calculating the adjustment for the current year to see if it
   * needs to be applied.  Note that we have to special-case 1900,
   * which is not a leap year though it is exactly divisible by
   * four.
   */

  time_tm.tm_year = -1;
  days_since_epoch = 0;
  days_per_year = 0;
  seconds_per_year = 0;
  do {
    days_since_epoch += days_per_year;
    time_sec -= seconds_per_year;
    ++time_tm.tm_year;
    days_per_year = DAYS_PER_YEAR;
    is_leap_year = (0 == (time_tm.tm_year % 4)) && (0 != time_tm.tm_year);
    if (is_leap_year) {
      ++days_per_year;
    }
    seconds_per_year = days_per_year * SECONDS_PER_DAY;
  } while (time_sec >= seconds_per_year);

  /* Same trick: adjust for previous month, calculate duration of
   * month, see if we're in that month.  Special-case February in leap
   * years.
   */

  days_per_month = 0;
  seconds_per_month = 0;
  time_tm.tm_mon = -1;
  do {
    days_since_epoch += days_per_month;
    time_tm.tm_yday += days_per_month;
    time_sec -= seconds_per_month;
    ++time_tm.tm_mon;
    days_per_month = daysPerMonth[time_tm.tm_mon];
    if (is_leap_year && (MONTH_IDX_FEBRUARY == time_tm.tm_mon)) {
      ++days_per_month;
    }
    seconds_per_month = days_per_month * SECONDS_PER_DAY;
  } while (time_sec >= seconds_per_month);

  /* Loop with subtraction rather than divide/modulus because this
   * goes on an embedded device and code size is smaller this way.
   * This calculation is not time-critical, and the loops are short
   * anyway.
   */
  while (time_sec >= SECONDS_PER_DAY) {
    time_sec -= SECONDS_PER_DAY;
    ++time_tm.tm_mday;
  }

  /* Adjust epoch/year day count then change tm_mday base to be 1 */
  days_since_epoch += time_tm.tm_mday;
  time_tm.tm_yday += time_tm.tm_mday;
  ++time_tm.tm_mday;

  while (time_sec >= SECONDS_PER_HOUR) {
    time_sec -= SECONDS_PER_HOUR;
    ++time_tm.tm_hour;
  }

  while (time_sec >= SECONDS_PER_MINUTE) {
    time_sec -= SECONDS_PER_MINUTE;
    ++time_tm.tm_min;
  }
  time_tm.tm_sec = time_sec;
  time_tm.tm_wday = (EPOCH_WDAY + days_since_epoch) % DAYS_PER_WEEK;
  return &time_tm;
}

/** Convert a POSIX tm structure to an RFC868 time (seconds since
 * 1900-01-01T00:00:00Z), without assuming that day-of-year is valid
 * on input
 */

static uint32_t
structToRfc868 (const struct tm* tmp) {
  uint32_t time_sec = 0;
  unsigned int days_since_epoch;
  int is_leap_year;
  int i;

  time_sec = tmp->tm_sec;
  time_sec += tmp->tm_min * SECONDS_PER_MINUTE;
  time_sec += tmp->tm_hour * SECONDS_PER_HOUR;

  /* 1900CE (year zero) is the only leap year in the representable
   * range that is not correctly identified by checking for a multiple
   * of four
   */
  is_leap_year = (0 == (tmp->tm_year % 4)) && (0 != tmp->tm_year);

  days_since_epoch = tmp->tm_mday - 1;
  for (i = 0; i < tmp->tm_mon; ++i) {
    days_since_epoch += daysPerMonth[i];
    if (is_leap_year && (MONTH_IDX_FEBRUARY == i)) {
      ++days_since_epoch;
    }
  }
  for (i = tmp->tm_year - 1; 0 <= i; --i) {
    days_since_epoch += DAYS_PER_YEAR;
    if ((0 == (i % 4)) && (0 != i)) {
      ++days_since_epoch;
    }
  }
  time_sec += days_since_epoch * SECONDS_PER_DAY;
  return time_sec;
}


int main (int argc,
          char* argv[]) {
  int ai;
  uint32_t time_sec;

  // date +'%s %c'
  // 1289395381 Wed 10 Nov 2010 07:23:01 AM CST => RFC868 3498384181
  // Test args: 2208988800 2398291200 2524521600 2629584000 3498384181

  for (ai = 1; ai < argc; ++ai) {
    char* ep;
    time_sec = strtoul(argv[ai], &ep, 0);
    if (ULONG_MAX == time_sec) {
      printf("Invalid integer: %s\n", argv[ai]);
    } else {
      const struct tm* time_tm = rfc868ToStruct(time_sec);

      if (time_tm) {
        uint32_t rtime_sec = structToRfc868(time_tm);
        printf("RFC868 time %u is yday %d inverts %u: %s", time_sec, time_tm->tm_yday, rtime_sec, asctime(time_tm));
        printf("RFC868 error %d\n", rtime_sec - time_sec);
      } else {
        printf("Error converting RFC868 time %u\n", time_sec);
      }
    }
  }
}
