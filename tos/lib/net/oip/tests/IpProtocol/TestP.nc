#include <stdio.h>
#include <netinet/in.h>
#include <netinet/icmp6.h>
#include <netinet/udp.h>
#include <stddef.h>
#include <arpa/inet.h>

module TestP {
  uses {
    interface Boot;
    interface IpProtocol[uint8_t protocol];
    interface WhiteboxIpSockets;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

  struct sk_buff skb;
  struct sockaddr_in6 sa1;
  struct sockaddr_in6 sa2;
  uint8_t garbage[64];

  void resetAddresses ()
  {
    memset(&sa1, 0, sizeof(sa1));
    sa1.sin6_family = AF_INET6;
    memset(&sa2, 0, sizeof(sa2));
    sa2.sin6_family = AF_INET6;
  }

  void testDefault ()
  {
    int rc;

    ASSERT_EQUAL(0, call WhiteboxIpSockets.IpProtocol_protocol(IPPROTO_TCP));
    ASSERT_EQUAL(-1, call WhiteboxIpSockets.IpProtocol_checksumOffset(IPPROTO_TCP));
    rc = call WhiteboxIpSockets.IpProtocol_processTransportHeader(IPPROTO_TCP, &skb, garbage, sizeof(garbage));
    ASSERT_EQUAL(0, rc);
    ASSERT_EQUAL(0, sa1.sin6_port);
    ASSERT_EQUAL(0, sa2.sin6_port);
    rc = call WhiteboxIpSockets.IpProtocol_storeTransportHeader(IPPROTO_TCP, skb.src, skb.dst, 15, garbage);
    ASSERT_EQUAL(0, rc);
    ASSERT_TRUE(! call WhiteboxIpSockets.IpProtocol_usesPorts(IPPROTO_TCP));

  }

  void testIcmp6 ()
  {
    int rc;

    ASSERT_EQUAL(IPPROTO_ICMPV6, call WhiteboxIpSockets.IpProtocol_protocol(IPPROTO_ICMPV6));
    ASSERT_EQUAL(2, call WhiteboxIpSockets.IpProtocol_checksumOffset(IPPROTO_ICMPV6));
    rc = call WhiteboxIpSockets.IpProtocol_processTransportHeader(IPPROTO_ICMPV6, &skb, garbage, sizeof(garbage));
    ASSERT_EQUAL(0, rc);
    ASSERT_EQUAL(0, sa1.sin6_port);
    ASSERT_EQUAL(0, sa2.sin6_port);
    rc = call WhiteboxIpSockets.IpProtocol_storeTransportHeader(IPPROTO_ICMPV6, skb.src, skb.dst, 15, garbage);
    ASSERT_EQUAL(0, rc);
    ASSERT_TRUE(! call WhiteboxIpSockets.IpProtocol_usesPorts(IPPROTO_ICMPV6));
  }

  void testUdp6 ()
  {
    struct udphdr hdr = { source: 0x0102, dest: 0x0405, len: 0, check: 0 };
    int rc;

    ASSERT_EQUAL(IPPROTO_UDP, call WhiteboxIpSockets.IpProtocol_protocol(IPPROTO_UDP));
    ASSERT_EQUAL(6, call WhiteboxIpSockets.IpProtocol_checksumOffset(IPPROTO_UDP));
    ASSERT_EQUAL(0, sa1.sin6_port);
    ASSERT_EQUAL(0, sa2.sin6_port);

    rc = call WhiteboxIpSockets.IpProtocol_processTransportHeader(IPPROTO_UDP, &skb, (uint8_t*)&hdr, sizeof(hdr));
    ASSERT_EQUAL(sizeof(hdr), rc);
    /* NOTE: Ports in socket addresses are expected to be stored in
     * network byte order, just as they are in the header.  Don't use
     * ?to?s. */
    ASSERT_EQUAL(0x0102, sa1.sin6_port);
    ASSERT_EQUAL(0x0405, sa2.sin6_port);

    sa1.sin6_port = 0xabcd;
    sa2.sin6_port = 0x8765;
    hdr.check = 1234;
    rc = call WhiteboxIpSockets.IpProtocol_storeTransportHeader(IPPROTO_UDP, skb.src, skb.dst, 15, (uint8_t*)&hdr);
    ASSERT_EQUAL(sizeof(hdr), rc);
    ASSERT_EQUAL(0xabcd, hdr.source);
    ASSERT_EQUAL(0x8765, hdr.dest);
    ASSERT_EQUAL(15 + sizeof(hdr), ntohs(hdr.len));
    resetAddresses();

    ASSERT_TRUE(call WhiteboxIpSockets.IpProtocol_usesPorts(IPPROTO_UDP));
  }

  event void Boot.booted ()
  {
    resetAddresses();

    memset(garbage, 0x5a, sizeof(garbage));

    memset(&skb, 0, sizeof(skb));
    skb.src = (struct sockaddr*)&sa1;
    skb.dst = (struct sockaddr*)&sa2;

    testDefault();
    testIcmp6();
    testUdp6();
    ALL_TESTS_PASSED();
  }
}
