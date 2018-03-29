#include <stdio.h>

module TestP {
  uses interface Boot;
  uses interface Rfc868;
#include <unittest/module_spec.h>
} implementation {

#include <unittest/module_impl.h>

  typedef struct test_t {
      uint32_t time_rfc868;
      struct tm time_tm;
  } test_t;

  const test_t tests[] = {
    { 2208988800UL, { tm_yday:0, tm_wday: 4, tm_year: 70, tm_mon: 0, tm_mday: 1, tm_hour: 0, tm_min: 0, tm_sec: 0 } },
    { 2398291200UL, { tm_yday:0, tm_wday: 4, tm_year: 76, tm_mon: 0, tm_mday: 1, tm_hour: 0, tm_min: 0, tm_sec: 0 } },
    { 2524521600UL, { tm_yday:0, tm_wday: 2, tm_year: 80, tm_mon: 0, tm_mday: 1, tm_hour: 0, tm_min: 0, tm_sec: 0 } },
    { 2629584000UL, { tm_yday:120, tm_wday: 0, tm_year: 83, tm_mon: 4, tm_mday: 1, tm_hour: 0, tm_min: 0, tm_sec: 0 } },
    { 3498384181UL, { tm_yday:313, tm_wday: 3, tm_year: 110, tm_mon: 10, tm_mday: 10, tm_hour: 13, tm_min: 23, tm_sec: 1 } },
    { 0, { tm_yday:0, tm_wday: 1, tm_year: 0, tm_mon: 0, tm_mday: 1, tm_hour: 0, tm_min: 0, tm_sec: 0 }  },
  };

  void testConversion () {
    const test_t* tp = tests;

    while (1) {
      error_t rc;
      struct tm time_tm;
      uint32_t time_rfc868;

      memset(&time_tm, 0xff, sizeof(time_tm));
      rc = call Rfc868.toTime(tp->time_rfc868, &time_tm);
      ASSERT_EQUAL(time_tm.tm_sec, tp->time_tm.tm_sec);
      ASSERT_EQUAL(time_tm.tm_min, tp->time_tm.tm_min);
      ASSERT_EQUAL(time_tm.tm_hour, tp->time_tm.tm_hour);
      ASSERT_EQUAL(time_tm.tm_mday, tp->time_tm.tm_mday);
      ASSERT_EQUAL(time_tm.tm_mon, tp->time_tm.tm_mon);
      ASSERT_EQUAL(time_tm.tm_year, tp->time_tm.tm_year);
      ASSERT_EQUAL(time_tm.tm_wday, tp->time_tm.tm_wday);
      ASSERT_EQUAL(time_tm.tm_yday, tp->time_tm.tm_yday);

      time_rfc868 = call Rfc868.fromTime(&tp->time_tm);
      ASSERT_EQUAL_U32(time_rfc868, tp->time_rfc868);

      if (! tp->time_rfc868) {
        break;
      }
      ++tp;
    }
  }

  void testEpochConstant () {
    error_t rc;
    struct tm posix;

    ASSERT_EQUAL_U32(2208988800UL, call Rfc868.posixEpochOffset());
    memset(&posix, 0xff, sizeof(posix));
    rc = call Rfc868.toTime(call Rfc868.posixEpochOffset(), &posix);
    ASSERT_EQUAL(0, posix.tm_sec);
    ASSERT_EQUAL(0, posix.tm_min);
    ASSERT_EQUAL(0, posix.tm_hour);
    ASSERT_EQUAL(1, posix.tm_mday);
    ASSERT_EQUAL(0, posix.tm_mon);
    ASSERT_EQUAL(70, posix.tm_year);
    ASSERT_EQUAL(4, posix.tm_wday);
    ASSERT_EQUAL(0, posix.tm_yday);
  }

  event void Boot.booted () {
    testEpochConstant();
    testConversion();
    ALL_TESTS_PASSED();
  }
}
