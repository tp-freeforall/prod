configuration TestAppC {
} implementation {
  components TestP;
  components MainC;

  TestP.Boot -> MainC;
  
  components Icmp6C;
  components Udp6C;
  components IpSocketsC;
  TestP.WhiteboxIpSockets -> IpSocketsC;

#include <unittest/config_impl.h>
}
