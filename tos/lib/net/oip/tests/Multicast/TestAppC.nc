#include "ppp.h"
#include <net/osian.h>

configuration TestAppC {
} implementation {
  components TestP;

  components MainC;
  TestP.Boot -> MainC;

  components DeviceIdentityC;
  TestP.DeviceIdentity -> DeviceIdentityC;

  components new TimerMilliC() as PeriodicC;
  TestP.Periodic -> PeriodicC;

  components PppIpv6DaemonC as PppDaemonC;
  TestP.Ppp -> PppDaemonC;

  components LedC;
  TestP.ConnectedLed -> LedC.Green;
  TestP.ErrorLed -> LedC.Red;
  TestP.RxToggleLed -> LedC.White;
  TestP.TxToggleLed -> LedC.Blue;

  components PppPrintfC;
  PppPrintfC.Ppp -> PppDaemonC;
  PppDaemonC.PppProtocol[PppPrintfC.Protocol] -> PppPrintfC;
  
  components new Udp6SocketC();
  TestP.UdpSocket -> Udp6SocketC;
  TestP.UdpDatagramSocket -> Udp6SocketC;
  TestP.NetworkInterface -> PppDaemonC;

  components new Ipv6SaaOsianSubnetC(OSIAN_ULA_SUBNET_GATEWAY) as Ipv6SaaGatewayC;
  Ipv6SaaGatewayC.NetworkInterface -> PppDaemonC;

  components Icmp6EchoRequestC;
}
