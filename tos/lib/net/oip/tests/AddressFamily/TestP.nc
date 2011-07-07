#include <stdio.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <net/ipv6.h>
#include <string.h>

module TestP {
  uses {
    interface Boot;
    interface AddressFamilies;
    interface AddressFamily as AfInet6;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

  static uint8_t rfc1071[] = { 0x00, 0x01, 0xf2, 0x03, 0xf4, 0xf5, 0xf6, 0xf7 };

  static uint8_t address6a_bits[] = { 0xfe, 0x80, 0, 0, 0, 0, 0,
                                      1, 2, 3, 4, 5, 6, 7 };
  static uint8_t address6b_bits[] = { 0x20, 0x01, 0x0d, 0xb8, 3, 4, 5,
                                      9, 8, 7, 6, 5, 4, 3, 2 };
  typedef union sockaddr_u {
    struct sockaddr sa;
    struct sockaddr_in6 s6;
  } sockaddr_u;

  sockaddr_u addressa;
  sockaddr_u addressb;
  
  struct sockaddr_in6* paddress6a = &addressa.s6;
  struct sockaddr* paddressa = &addressa.sa;
  struct sockaddr_in6* paddress6b = &addressb.s6;
  struct sockaddr* paddressb = &addressb.sa;

  void initializeAddresses ()
  {
    paddress6a->sin6_family = AF_INET6;
    memcpy(paddress6a->sin6_addr.s6_addr, address6a_bits, sizeof(address6a_bits));
    paddress6b->sin6_family = AF_INET6;
    memcpy(paddress6b->sin6_addr.s6_addr, address6b_bits, sizeof(address6b_bits));
    ASSERT_TRUE(0 != memcmp(&addressa, &addressb, sizeof(addressa)));
  }

  void checkAddress (struct sockaddr* saddr,
                     struct sockaddr* daddr,
                     uint16_t expected_csum_nbo)
  {
    uint16_t csum;

    csum = call AfInet6.ipMagicChecksum(saddr, daddr, 0, 0, 0);
    ASSERT_EQUAL(expected_csum_nbo, htons(csum));
    csum = call AddressFamilies.ipMagicChecksum(saddr, daddr, 0, 0, 0);
    ASSERT_EQUAL(expected_csum_nbo, htons(csum));
    csum = call AfInet6.ipMagicChecksum(daddr, saddr, 0, 0, 0);
    ASSERT_EQUAL(expected_csum_nbo, htons(csum));
    csum = call AddressFamilies.ipMagicChecksum(daddr, saddr, 0, 0, 0);
    ASSERT_EQUAL(expected_csum_nbo, htons(csum));
  }

  void testAfInet6Checksum ()
  {
    sockaddr_u saddr;
    sockaddr_u daddr;
    struct in6_addr* s6p = &saddr.s6.sin6_addr;
    struct in6_addr* d6p = &daddr.s6.sin6_addr;
    uint16_t csum;

    memset(&saddr, 0, sizeof(saddr));
    memset(&daddr, 0, sizeof(daddr));
    saddr.s6.sin6_family = daddr.s6.sin6_family = AF_INET6;
    ASSERT_TRUE(! (1 & (uint16_t)(s6p)));
    ASSERT_TRUE(! (1 & (uint16_t)(d6p)));
    csum = call AfInet6.ipMagicChecksum(&saddr.sa, &daddr.sa, 0, 0, 0);
    ASSERT_EQUAL(0, csum);

    /* Payload length passed in host order, sums in network order */
    csum = call AfInet6.ipMagicChecksum(&saddr.sa, &daddr.sa, 0x0102, 0, 0);
    ASSERT_EQUAL(0x0201, csum);

    /* Protocol sums in network order */
    csum = call AfInet6.ipMagicChecksum(&saddr.sa, &daddr.sa, 0, 1, 0);
    ASSERT_EQUAL(0x0100, csum);

    csum = call AfInet6.ipMagicChecksum(&saddr.sa, &daddr.sa, 0, 0, 0xffff);
    ASSERT_EQUAL(0xffff, csum);

    csum = call AfInet6.ipMagicChecksum(&saddr.sa, &daddr.sa, 2, 0, 0xffff);
    ASSERT_EQUAL(0x200, csum);
    csum = call AfInet6.ipMagicChecksum(&saddr.sa, &daddr.sa, 0x0101, 1, 0);
    ASSERT_EQUAL(0x0201, csum);

    saddr.sa.sa_family = AF_UNSPEC;
    csum = call AddressFamilies.ipMagicChecksum(&saddr.sa, &daddr.sa, 0, 1, 0);
    ASSERT_EQUAL(0x0100, csum);
    csum = call AddressFamilies.ipMagicChecksum(&daddr.sa, &saddr.sa, 0, 1, 0);
    ASSERT_EQUAL(0, csum);
    saddr.s6.sin6_family = AF_INET6;

    memset(saddr.s6.sin6_addr.s6_addr, 0, sizeof(saddr.s6.sin6_addr));
    memcpy(saddr.s6.sin6_addr.s6_addr + 0, rfc1071, sizeof(rfc1071));
    checkAddress(&saddr.sa, &daddr.sa, 0xddf2);
    checkAddress(&daddr.sa, &saddr.sa, 0xddf2);

    memset(saddr.s6.sin6_addr.s6_addr, 0, sizeof(saddr.s6.sin6_addr));
    memcpy(saddr.s6.sin6_addr.s6_addr + 4, rfc1071, sizeof(rfc1071));
    checkAddress(&saddr.sa, &daddr.sa, 0xddf2);
    checkAddress(&daddr.sa, &saddr.sa, 0xddf2);

    memset(saddr.s6.sin6_addr.s6_addr, 0, sizeof(saddr.s6.sin6_addr));
    memcpy(saddr.s6.sin6_addr.s6_addr + 8, rfc1071, sizeof(rfc1071));
    checkAddress(&saddr.sa, &daddr.sa, 0xddf2);
    checkAddress(&daddr.sa, &saddr.sa, 0xddf2);
  }

  void testLength ()
  {
    ASSERT_EQUAL(sizeof(struct sockaddr_in6), call AfInet6.sockaddrLength());
    ASSERT_EQUAL(sizeof(struct sockaddr_in6), call AddressFamilies.sockaddrLength(AF_INET6));
    ASSERT_EQUAL(0, call AddressFamilies.sockaddrLength(AF_UNSPEC))
  }

  void testInaddr ()
  {
    struct sockaddr_in6 sa6;
    
    ASSERT_EQUAL(sizeof(sa6.sin6_addr), call AfInet6.inaddrLength());
    ASSERT_EQUAL_PTR(&sa6.sin6_addr, call AfInet6.inaddrPointer((struct sockaddr*)&sa6));
  }

  void testPort ()
  {
    sockaddr_u addr;
    
    memset(&addr, 0, sizeof(addr));
    addr.s6.sin6_port = 12345;
    ASSERT_EQUAL(12345, call AfInet6.getPort(&addr.sa));

    /* Require sa_family to be set for generic interface */
    ASSERT_EQUAL(0, call AddressFamilies.getPort(&addr.sa));
    addr.s6.sin6_family = AF_INET6;
    ASSERT_EQUAL(12345, call AfInet6.getPort(&addr.sa));
  }

  void testWildcard ()
  {
    sockaddr_u addr;

    memset(&addr, 0, sizeof(addr));
    ASSERT_TRUE(! call AddressFamilies.addressIsWildcard(&addr.sa));
    addr.s6.sin6_family = AF_INET6;
    ASSERT_TRUE(call AddressFamilies.addressIsWildcard(&addr.sa));
    addr.s6.sin6_addr.s6_addr[15] = 1;
    ASSERT_TRUE(! call AddressFamilies.addressIsWildcard(&addr.sa));
  }

  void testMulticast ()
  {
    sockaddr_u addr;

    memset(&addr, 0, sizeof(addr));
    ASSERT_TRUE(! call AddressFamilies.addressIsMulticast(&addr.sa));
    addr.s6.sin6_family = AF_INET6;
    ASSERT_TRUE(! call AddressFamilies.addressIsMulticast(&addr.sa));
    addr.s6.sin6_addr.s6_addr[0] = 0xff;
    ASSERT_TRUE(call AddressFamilies.addressIsMulticast(&addr.sa));
    addr.s6.sin6_addr.s6_addr[0] = 0xfe;
    ASSERT_TRUE(! call AddressFamilies.addressIsMulticast(&addr.sa));
  }

  void testIpHeader ()
  {
    struct ipv6hdr h1;
    struct ipv6hdr h2;
    int rv;
    const uint16_t payload_len = 12345;
    const uint8_t nexthdr = 17;

    memset(&h1, 0, sizeof(h1));
    h1.version = 6;
    h1.payload_len = htons(payload_len);
    h1.nexthdr = nexthdr;
    h1.hop_limit = 64;
    memcpy(h1.saddr.s6_addr, paddress6a->sin6_addr.s6_addr, sizeof(addressa));
    memcpy(h1.daddr.s6_addr, paddress6b->sin6_addr.s6_addr, sizeof(addressb));

    memset(&h2, 0xa5, sizeof(h2));
    rv = call AfInet6.storeIpHeader(paddressa, paddressb, payload_len, nexthdr, 0);
    ASSERT_EQUAL(rv, sizeof(h1));
    rv = call AfInet6.storeIpHeader(paddressa, paddressb, payload_len, nexthdr, (uint8_t*)&h2);
    ASSERT_EQUAL(rv, sizeof(h2));
    ASSERT_EQUAL(0, memcmp(&h1, &h2, sizeof(h1)));

    memset(&h2, 0xa5, sizeof(h2));
    rv = call AddressFamilies.storeIpHeader(paddressa, paddressb, payload_len, nexthdr, 0);
    ASSERT_EQUAL(rv, sizeof(h1));
    rv = call AddressFamilies.storeIpHeader(paddressa, paddressb, payload_len, nexthdr, (uint8_t*)&h2);
    ASSERT_EQUAL(rv, sizeof(h2));
    ASSERT_EQUAL(0, memcmp(&h1, &h2, sizeof(h1)));

    paddressa->sa_family = AF_UNSPEC;
    rv = call AddressFamilies.storeIpHeader(paddressa, paddressb, payload_len, nexthdr, (uint8_t*)&h2);
    ASSERT_EQUAL(rv, sizeof(h2));
    rv = call AddressFamilies.storeIpHeader(paddressb, paddressa, payload_len, nexthdr, (uint8_t*)&h2);
    ASSERT_EQUAL(rv, -1);
    paddressa->sa_family = AF_INET6;

  }

  void testIn6Addrs ()
  {
    int i;
    struct in6_addr linklocal;
    struct in6_addr all_nodes;
    struct in6_addr v4_mapped;
    struct in6_addr v4_compat;

    memset(&linklocal, 0, sizeof(linklocal));
    linklocal.s6_addr16[0] = htons(0xfe80);
    linklocal.s6_addr16[7] = htons(1);

    memset(&all_nodes, 0, sizeof(all_nodes));
    all_nodes.s6_addr16[0] = htons(0xff01);
    all_nodes.s6_addr[15] = 1;

    memset(&v4_compat, 0, sizeof(v4_compat));
    *(uint32_t*)(12 + v4_compat.s6_addr) = htonl(0x01020304);

    memcpy(&v4_mapped, &v4_compat, sizeof(v4_mapped));
    v4_mapped.s6_addr16[5] = 0xffff;

    printf("v4_mapped: %s\r\n", inet_ntop(AF_INET6, &v4_mapped));
    printf("v4_compat: %s\r\n", inet_ntop(AF_INET6, &v4_compat));
    
    for (i = 0; i < 15; ++i) {
      ASSERT_EQUAL(0, in6addr_any.s6_addr[i]);
      ASSERT_EQUAL(0, in6addr_loopback.s6_addr[i]);
    }
    ASSERT_EQUAL(0, in6addr_any.s6_addr[15]);
    ASSERT_EQUAL(1, in6addr_loopback.s6_addr[15]);

    ASSERT_TRUE(IN6_IS_ADDR_UNSPECIFIED(&in6addr_any));
    ASSERT_TRUE(! IN6_IS_ADDR_UNSPECIFIED(&in6addr_loopback));
    ASSERT_TRUE(! IN6_IS_ADDR_UNSPECIFIED(&all_nodes));
    ASSERT_TRUE(! IN6_IS_ADDR_UNSPECIFIED(&linklocal));
    ASSERT_TRUE(! IN6_IS_ADDR_UNSPECIFIED(&v4_mapped));
    ASSERT_TRUE(! IN6_IS_ADDR_UNSPECIFIED(&v4_compat));

    ASSERT_TRUE(! IN6_IS_ADDR_LOOPBACK(&in6addr_any));
    ASSERT_TRUE(IN6_IS_ADDR_LOOPBACK(&in6addr_loopback));
    ASSERT_TRUE(! IN6_IS_ADDR_LOOPBACK(&all_nodes));
    ASSERT_TRUE(! IN6_IS_ADDR_LOOPBACK(&linklocal));
    ASSERT_TRUE(! IN6_IS_ADDR_LOOPBACK(&v4_mapped));
    ASSERT_TRUE(! IN6_IS_ADDR_LOOPBACK(&v4_compat));

    ASSERT_TRUE(! IN6_IS_ADDR_MULTICAST(&in6addr_any));
    ASSERT_TRUE(! IN6_IS_ADDR_MULTICAST(&in6addr_loopback));
    ASSERT_TRUE(IN6_IS_ADDR_MULTICAST(&all_nodes));
    ASSERT_TRUE(! IN6_IS_ADDR_MULTICAST(&linklocal));
    ASSERT_TRUE(! IN6_IS_ADDR_MULTICAST(&v4_compat));
    ASSERT_TRUE(! IN6_IS_ADDR_MULTICAST(&v4_mapped));

    ASSERT_TRUE(! IN6_IS_ADDR_LINKLOCAL(&in6addr_any));
    ASSERT_TRUE(! IN6_IS_ADDR_LINKLOCAL(&in6addr_loopback));
    ASSERT_TRUE(! IN6_IS_ADDR_LINKLOCAL(&all_nodes));
    ASSERT_TRUE(IN6_IS_ADDR_LINKLOCAL(&linklocal));
    ASSERT_TRUE(! IN6_IS_ADDR_LINKLOCAL(&v4_compat));
    ASSERT_TRUE(! IN6_IS_ADDR_LINKLOCAL(&v4_mapped));

    ASSERT_TRUE(! IN6_IS_ADDR_V4COMPAT(&in6addr_any));
    ASSERT_TRUE(! IN6_IS_ADDR_V4COMPAT(&in6addr_loopback));
    ASSERT_TRUE(! IN6_IS_ADDR_V4COMPAT(&all_nodes));
    ASSERT_TRUE(! IN6_IS_ADDR_V4COMPAT(&linklocal));
    ASSERT_TRUE(IN6_IS_ADDR_V4COMPAT(&v4_compat));
    ASSERT_TRUE(! IN6_IS_ADDR_V4COMPAT(&v4_mapped));

    ASSERT_TRUE(! IN6_IS_ADDR_V4MAPPED(&in6addr_any));
    ASSERT_TRUE(! IN6_IS_ADDR_V4MAPPED(&in6addr_loopback));
    ASSERT_TRUE(! IN6_IS_ADDR_V4MAPPED(&all_nodes));
    ASSERT_TRUE(! IN6_IS_ADDR_V4MAPPED(&linklocal));
    ASSERT_TRUE(! IN6_IS_ADDR_V4MAPPED(&v4_compat));
    ASSERT_TRUE(IN6_IS_ADDR_V4MAPPED(&v4_mapped));

    ASSERT_TRUE(! IN6_IS_ADDR_MC_NODELOCAL(&in6addr_any));
    ASSERT_TRUE(! IN6_IS_ADDR_MC_NODELOCAL(&in6addr_loopback));
    ASSERT_TRUE(IN6_IS_ADDR_MC_NODELOCAL(&all_nodes));
    ASSERT_TRUE(! IN6_IS_ADDR_MC_NODELOCAL(&linklocal));
    ASSERT_TRUE(! IN6_IS_ADDR_MC_NODELOCAL(&v4_compat));
    ASSERT_TRUE(! IN6_IS_ADDR_MC_NODELOCAL(&v4_mapped));
  }

  void testPrefixMatch ()
  {
    uint8_t prefix[] = { 0xfe, 0xc0 };
    struct sockaddr sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_family = AF_UNSPEC;

    ASSERT_TRUE(call AfInet6.addressPrefixMatch(paddressa, prefix, 8));
    ASSERT_TRUE(call AfInet6.addressPrefixMatch(paddressa, prefix, 9));
    ASSERT_TRUE(! call AfInet6.addressPrefixMatch(paddressa, prefix, 10));
    ASSERT_TRUE(call AfInet6.addressPrefixMatch(paddressa, address6a_bits, 10));
    ASSERT_TRUE(call AddressFamilies.addressPrefixMatch(paddressa, address6a_bits, 10));

    /* Prefix length zero trivially true for implemented families, not
     * for non-implemented families */
    ASSERT_TRUE(call AfInet6.addressPrefixMatch(paddressa, address6a_bits, 0));
    ASSERT_TRUE(! call AddressFamilies.addressPrefixMatch(&sa, address6a_bits, 0));
  }

  void testPrefixLength ()
  {
    union {
        struct sockaddr_in6 s6;
        struct sockaddr sa;
    } addrc;

    struct sockaddr sa;
    sa.sa_family = AF_UNSPEC;
    ASSERT_EQUAL(-1, call AddressFamilies.prefixMatchLength(0, 0));
    ASSERT_EQUAL(-1, call AddressFamilies.prefixMatchLength(0, &sa));
    ASSERT_EQUAL(-1, call AddressFamilies.prefixMatchLength(&sa, 0));
    ASSERT_EQUAL(-1, call AddressFamilies.prefixMatchLength(&sa, paddressa));
    ASSERT_EQUAL(128, call AddressFamilies.prefixMatchLength(paddressa, paddressa));
    ASSERT_EQUAL(0, call AddressFamilies.prefixMatchLength(paddressa, paddressb));

    memcpy(&addrc.s6, &addressa.s6, sizeof(addressa.s6));
    ASSERT_EQUAL(128, call AddressFamilies.prefixMatchLength(paddressa, &addrc.sa));
    addrc.s6.sin6_addr.s6_addr[4] ^= 0x20;
    ASSERT_EQUAL(32 + 2, call AddressFamilies.prefixMatchLength(paddressa, &addrc.sa));
  }

  event void Boot.booted () {
    initializeAddresses();
    testAfInet6Checksum();
    testLength();
    testInaddr();
    testPort();
    testWildcard();
    testMulticast();
    testIpHeader();
    testIn6Addrs();
    testPrefixMatch();
    testPrefixLength();
    ALL_TESTS_PASSED();
  }
}
