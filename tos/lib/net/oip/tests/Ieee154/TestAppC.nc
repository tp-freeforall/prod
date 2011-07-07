#include "ppp.h"

configuration TestAppC {
} implementation {
  components TestP;

  components MainC;
  TestP.Boot -> MainC;

  components new Udp6SocketC();
  TestP.UdpSocket -> Udp6SocketC;
  TestP.UdpDatagramSocket -> Udp6SocketC;

  components new TimerMilliC() as PeriodicC;
  TestP.Periodic -> PeriodicC;

  components new Ieee154OdiAddressC(1);
  MainC.SoftwareInit -> Ieee154OdiAddressC;

  components Ipv6Ieee154C;
  TestP.RadioNicControl -> Ipv6Ieee154C;
  TestP.NetworkInterface -> Ipv6Ieee154C;
 
  components Icmp6EchoRequestC;
  // components Udp6EchoC;

  components SerialPrintfC;

}


