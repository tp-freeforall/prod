#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <net/checksum.h>

module TestP {
  uses {
    interface Boot;
    interface AddressFamily as AfInet6;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

  static uint8_t rfc1071[] = { 0x00, 0x01, 0xf2, 0x03, 0xf4, 0xf5, 0xf6, 0xf7 };

  void testCsumPartialFast ()
  {
    uint16_t csum;

    csum = csum_partial_fast(rfc1071, sizeof(rfc1071), 0);
    ASSERT_EQUAL(0xddf2, htons(csum));
    ASSERT_EQUAL(0x220d, htons(csum_fold(csum)));
    csum = csum_partial_fast(rfc1071, sizeof(rfc1071), ntohs(0x220d));
    ASSERT_EQUAL(0, htons(csum_fold(csum)));
  }

  void testCsumPartialCopyFast ()
  {
    uint16_t csum;
    uint8_t dst[sizeof(rfc1071)];

    memset(dst, 0, sizeof(dst));
    ASSERT_TRUE(0 != memcmp(dst, rfc1071, sizeof(rfc1071)));
    csum = csum_partial_copy_fast(rfc1071, dst, sizeof(rfc1071), 0);
    ASSERT_EQUAL(0xddf2, htons(csum));
    ASSERT_EQUAL(0x220d, htons(csum_fold(csum)));
    ASSERT_TRUE(0 == memcmp(dst, rfc1071, sizeof(rfc1071)));

    memset(dst, 0, sizeof(dst));
    ASSERT_TRUE(0 != memcmp(dst, rfc1071, sizeof(rfc1071)));
    csum = csum_partial_copy_fast(rfc1071, dst, sizeof(rfc1071), ntohs(0x220d));
    ASSERT_EQUAL(0, htons(csum_fold(csum)));
    ASSERT_TRUE(0 == memcmp(dst, rfc1071, sizeof(rfc1071)));
  }

  void testCsumFold ()
  {
    uint16_t csum;
    uint8_t data[] = { 0xff, 0xff };

    csum = csum_partial_fast(data, sizeof(data), 0);
    ASSERT_EQUAL(0xFFFF, csum);
    csum = csum_fold(csum);
    ASSERT_EQUAL(0, csum);
    /* As we're emulating the Linux checksum interface, and they don't
     * deal with checksums that compute to zero in the helper
     * functions, neither will we.  IpSocketsP will replace the
     * computed value with CSUM_MANGLED_0 if necessary. */
    ASSERT_EQUAL(0xFFFF, CSUM_MANGLED_0);
  }

  event void Boot.booted () {
    testCsumPartialFast();
    testCsumPartialCopyFast();
    testCsumFold();
    ALL_TESTS_PASSED();
  }
}
