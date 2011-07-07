#include <sys/socket.h>
#include <netinet/in.h>

configuration TestAppC {
} implementation {
  components TestP;
  components MainC;

  TestP.Boot -> MainC;
  
  components new IpSocketC(AF_INET6, SOCK_RAW, IPPROTO_RAW);
  TestP.IpSocket -> IpSocketC;

  /* Necessary for getnameinfo on sockaddr_in6 objects */
  components Ipv6C;

  components IpSocketsC;
  TestP.WhiteboxIpSockets -> IpSocketsC;

#include <unittest/config_impl.h>
}
