#include <stdio.h>
#include <arpa/inet.h>
#include <netinet/in.h>

module TestP {
  uses {
    interface Boot;
    interface IpSocket;
    interface WhiteboxIpSockets;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

  struct sockaddr_in6 s6a;
  struct sockaddr* sap;
  struct sockaddr_in6 s6b;
  struct sockaddr* sbp;

  void testDescriptor ()
  {
    ASSERT_EQUAL(0, call IpSocket.descriptor());
  }

  void testBind ()
  {
    error_t rc;
    
    ASSERT_EQUAL_PTR(0, call IpSocket.getsockname());
    rc = call IpSocket.bind(sap);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL(EALREADY, call IpSocket.bind(sap));
    ASSERT_EQUAL(EALREADY, call IpSocket.bind(sbp));
    ASSERT_EQUAL_PTR(sap, call IpSocket.getsockname());

    rc = call IpSocket.bind(0);
    ASSERT_EQUAL_PTR(0, call IpSocket.getsockname());
  }

  void testConnect ()
  {
    error_t rc;
    
    ASSERT_EQUAL_PTR(0, call IpSocket.getpeername());
    rc = call IpSocket.connect(sbp);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL(EALREADY, call IpSocket.connect(sap));
    ASSERT_EQUAL(EALREADY, call IpSocket.connect(sbp));
    ASSERT_EQUAL_PTR(sbp, call IpSocket.getpeername());

    rc = call IpSocket.connect(0);
    ASSERT_EQUAL_PTR(0, call IpSocket.getpeername());
  }

  void testBindConnect ()
  {
    error_t rc;

    rc = call IpSocket.bind(sap);
    ASSERT_EQUAL(SUCCESS, rc);
    rc = call IpSocket.connect(sbp);
    ASSERT_EQUAL(SUCCESS, rc);

    ASSERT_TRUE(sap != sbp);
    ASSERT_EQUAL_PTR(sap, call IpSocket.getsockname());
    ASSERT_EQUAL_PTR(sbp, call IpSocket.getpeername());
    
    rc = call IpSocket.connect(0);
    ASSERT_EQUAL(SUCCESS, rc);
    rc = call IpSocket.bind(0);
    ASSERT_EQUAL(SUCCESS, rc);
  }

  void testSocketOptions ()
  {
    int value;
    socklen_t value_len;

    /* No support for socket level IPPROTO_TCP */
    ASSERT_EQUAL(FAIL, call WhiteboxIpSockets.SocketLevelOptions_getsockopt(IPPROTO_TCP, call IpSocket.descriptor(), SO_TYPE, &value, &value_len));
    ASSERT_EQUAL(FAIL, call WhiteboxIpSockets.SocketLevelOptions_setsockopt(IPPROTO_TCP, call IpSocket.descriptor(), SO_TYPE, &value, value_len));

    value = -1;
    value_len = sizeof(value);
    ASSERT_EQUAL(SUCCESS, call WhiteboxIpSockets.SocketLevelOptions_getsockopt(SOL_SOCKET, call IpSocket.descriptor(), SO_TYPE, &value, &value_len));
    ASSERT_EQUAL(SOCK_RAW, value);
    ASSERT_EQUAL(EINVAL, call WhiteboxIpSockets.SocketLevelOptions_setsockopt(SOL_SOCKET, call IpSocket.descriptor(), SO_TYPE, &value, value_len));

    ASSERT_EQUAL(EINVAL, call WhiteboxIpSockets.SocketLevelOptions_getsockopt(SOL_SOCKET, call IpSocket.descriptor(), 0, &value, &value_len));
    ASSERT_EQUAL(EINVAL, call WhiteboxIpSockets.SocketLevelOptions_setsockopt(SOL_SOCKET, call IpSocket.descriptor(), 0, &value, value_len));
  }

  event void Boot.booted () {
    memset(&s6a, 0, sizeof(s6a));
    sap = (struct sockaddr*)&s6a;
    s6a.sin6_family = AF_INET6;
    s6a.sin6_addr.s6_addr16[0] = htons(0xfe80);
    s6a.sin6_addr.s6_addr16[7] = htons(1);
    printf("Test address %p A: %s\r\n", sap, getnameinfo(sap));

    memset(&s6b, 0, sizeof(s6b));
    sbp = (struct sockaddr*)&s6b;
    s6b.sin6_family = AF_INET6;
    s6b.sin6_addr.s6_addr16[0] = htons(0x2001);
    s6b.sin6_addr.s6_addr16[1] = htons(0x0db8);
    s6b.sin6_addr.s6_addr16[7] = htons(1);
    printf("Test address %p B: %s\r\n", sbp, getnameinfo(sbp));

    testDescriptor();
    testBind();
    testConnect();
    testBindConnect();
    testSocketOptions();
    ALL_TESTS_PASSED();
  }
}
