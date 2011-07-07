#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/icmp6.h>
#include <arpa/inet.h>

module TestP {
  uses {
    interface Boot;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

  void testIn6Macros ()
  {
    struct in6_addr ia;

    memset(&ia, 0, sizeof(ia));
    ASSERT_TRUE(! IN6_IS_ADDR_LINKLOCAL(&ia));
    ia.s6_addr[0] = 0xfe;
    ia.s6_addr[1] = 0x80;
    ASSERT_TRUE(IN6_IS_ADDR_LINKLOCAL(&ia));
    ia.s6_addr[1] = 0x40;
    ASSERT_TRUE(! IN6_IS_ADDR_LINKLOCAL(&ia));
  }

  void testIcmp6 ()
  {
    const uint8_t data[] = { 128, 2, 3, 4, 0, 25, 0, 3 };
    struct icmp6_hdr h1;

    memset(&h1, 0, sizeof(h1));
    ASSERT_EQUAL(8, sizeof(h1));
    memcpy(&h1, data, sizeof(data));
    ASSERT_EQUAL(128, h1.icmp6_type);
    ASSERT_EQUAL(2, h1.icmp6_code);
    ASSERT_EQUAL(0x0304, ntohs(h1.icmp6_cksum));
    ASSERT_EQUAL(25, ntohs(h1.icmp6_data16[0]));
    ASSERT_EQUAL(3, ntohs(h1.icmp6_data16[1]));
  }

  event void Boot.booted () {
    testIn6Macros();
    testIcmp6();
    ALL_TESTS_PASSED();
  }
}
