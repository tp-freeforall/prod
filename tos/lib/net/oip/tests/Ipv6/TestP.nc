#include <stdio.h>
#include <netinet/in.h>
#include <net/socket.h>

module TestP {
  uses {
    interface Boot;
    interface IpSocket as UdpSocket;
    interface NetworkInterface;
    interface AddressFamilies;
    interface WhiteboxNetworkInterfaces;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

  event void NetworkInterface.interfaceState (oip_nic_state_t state) { }

  void testHopOptions ()
  {
    int i;
    int multicast_hops = 2;
    int unicast_hops = 32;
    socklen_t socklen;

    i = -1;
    socklen = sizeof(i);
    ASSERT_EQUAL(SUCCESS, call UdpSocket.getsockopt(IPPROTO_IPV6, IPV6_MULTICAST_HOPS, &i, &socklen));
    ASSERT_EQUAL(64, i);

    i = -1;
    socklen = sizeof(i);
    ASSERT_EQUAL(SUCCESS, call UdpSocket.getsockopt(IPPROTO_IPV6, IPV6_UNICAST_HOPS, &i, &socklen));
    ASSERT_EQUAL(64, i);

    i = multicast_hops;
    socklen = sizeof(i);
    ASSERT_EQUAL(SUCCESS, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_MULTICAST_HOPS, &i, socklen));

    i = -1;
    socklen = sizeof(i);
    ASSERT_EQUAL(SUCCESS, call UdpSocket.getsockopt(IPPROTO_IPV6, IPV6_MULTICAST_HOPS, &i, &socklen));
    ASSERT_EQUAL(multicast_hops, i);

    i = unicast_hops;
    socklen = sizeof(i);
    ASSERT_EQUAL(SUCCESS, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_UNICAST_HOPS, &i, socklen));

    i = -1;
    socklen = sizeof(i);
    ASSERT_EQUAL(SUCCESS, call UdpSocket.getsockopt(IPPROTO_IPV6, IPV6_UNICAST_HOPS, &i, &socklen));
    ASSERT_EQUAL(unicast_hops, i);
  }

  void testMulticastIfOption ()
  {
    int i;
    socklen_t socklen;
    
    i = -1;
    socklen = sizeof(i);
    ASSERT_EQUAL(SUCCESS, call UdpSocket.getsockopt(IPPROTO_IPV6, IPV6_MULTICAST_IF, &i, &socklen));
    ASSERT_EQUAL(0, i);

    i = call NetworkInterface.id();
    ASSERT_TRUE(0 != i);
    socklen = sizeof(i);
    ASSERT_EQUAL(SUCCESS, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_MULTICAST_IF, &i, socklen));

    i = -1;
    socklen = sizeof(i);
    ASSERT_EQUAL(SUCCESS, call UdpSocket.getsockopt(IPPROTO_IPV6, IPV6_MULTICAST_IF, &i, &socklen));
    ASSERT_EQUAL(call NetworkInterface.id(), i);

    i = 1 + OIP_NETWORK_INTERFACE_MAX;
    socklen = sizeof(i);
    ASSERT_EQUAL(EINVAL, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_MULTICAST_IF, &i, socklen));

    i = 0;
    socklen = sizeof(i);
    ASSERT_EQUAL(SUCCESS, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_MULTICAST_IF, &i, socklen));

    i = -1;
    socklen = sizeof(i);
    ASSERT_EQUAL(SUCCESS, call UdpSocket.getsockopt(IPPROTO_IPV6, IPV6_MULTICAST_IF, &i, &socklen));
    ASSERT_EQUAL(0, i);
  }

  void testGroups ()
  {
    const struct sockaddr* const* addresses = call WhiteboxNetworkInterfaces.addresses(call NetworkInterface.id());
    const struct sockaddr* const* groups = call WhiteboxNetworkInterfaces.groups(call NetworkInterface.id());
    union {
        struct sockaddr sa;
        struct sockaddr_in6 s6;
    } mcast;
    
    /* No bound addresses */
    ASSERT_EQUAL_PTR(0, addresses[0]);
    ASSERT_EQUAL_PTR(0, groups[0]);

    memset(&mcast, 0, sizeof(mcast));

    mcast.s6.sin6_family = AF_UNSPEC;
    ASSERT_EQUAL(EINVAL, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_JOIN_GROUP, &mcast.sa, sizeof(mcast.s6)));
    ASSERT_EQUAL(EINVAL, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_LEAVE_GROUP, &mcast.sa, sizeof(mcast.s6)));
    ASSERT_EQUAL_PTR(0, groups[0]);
    
    mcast.s6.sin6_family = AF_INET6;

    /* Can't use unicast addresses */
    mcast.s6.sin6_addr.s6_addr[0] = 0xfe;
    mcast.s6.sin6_addr.s6_addr[1] = 0x80;
    mcast.s6.sin6_addr.s6_addr[15] = 1;
    ASSERT_EQUAL(EINVAL, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_JOIN_GROUP, &mcast.sa, sizeof(mcast.s6)));
    ASSERT_EQUAL(EINVAL, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_LEAVE_GROUP, &mcast.sa, sizeof(mcast.s6)));
    ASSERT_EQUAL_PTR(0, groups[0]);
    
    mcast.s6.sin6_addr.s6_addr[0] = 0xff;
    mcast.s6.sin6_addr.s6_addr[1] = 0x01;

    /* Can't have undefined scope */
    ASSERT_EQUAL(EINVAL, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_JOIN_GROUP, &mcast.sa, sizeof(mcast.s6)));
    ASSERT_EQUAL(EINVAL, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_LEAVE_GROUP, &mcast.sa, sizeof(mcast.s6)));
    ASSERT_EQUAL_PTR(0, groups[0]);

    mcast.s6.sin6_scope_id = call NetworkInterface.id();
    ASSERT_EQUAL(SUCCESS, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_JOIN_GROUP, &mcast.sa, sizeof(mcast.s6)));
    ASSERT_TRUE(0 == addresses[0]);
    ASSERT_TRUE(0 != groups[0]);
    ASSERT_TRUE(call AddressFamilies.addressEqual(groups[0], (const struct sockaddr*)&mcast.sa));

    ASSERT_EQUAL(1, OIP_GROUPS_PER_SOCKET_MAX);
    ASSERT_EQUAL(ENOMEM, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_JOIN_GROUP, &mcast.sa, sizeof(mcast.s6)));

    ASSERT_EQUAL(SUCCESS, call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_LEAVE_GROUP, &mcast.sa, sizeof(mcast.s6)));
    ASSERT_TRUE(0 == groups[0]);

  }

  event void Boot.booted () {
    testHopOptions();
    testMulticastIfOption();
    testGroups();
    ALL_TESTS_PASSED();
  }
}
