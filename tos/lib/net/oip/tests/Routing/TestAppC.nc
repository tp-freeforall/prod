#include "ppp.h"

configuration TestAppC {
} implementation {
  components TestP;

  components MainC;
  TestP.Boot -> MainC;

  components PppIpv6DaemonC as PppDaemonC;
  TestP.PppControl -> PppDaemonC;
  TestP.PppNic -> PppDaemonC.NetworkInterface;

  components new Ipv6SaaStaticC() as PppSaaC;
  PppSaaC.NetworkInterface -> PppDaemonC;

  components Ipv6Ieee154C;
  TestP.Ieee154Control -> Ipv6Ieee154C;
  TestP.Ieee154Nic -> Ipv6Ieee154C;
 
  components new Ipv6SaaStaticC() as Ieee154SaaC;
  Ieee154SaaC.NetworkInterface -> Ipv6Ieee154C;

  components PppPrintfC;
  PppPrintfC.Ppp -> PppDaemonC;
  PppDaemonC.PppProtocol[PppPrintfC.Protocol] -> PppPrintfC;
  
  components Icmp6EchoRequestC;
  components Udp6EchoC;

}


