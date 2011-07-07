#include <net/osian.h>

configuration TestAppC {
} implementation {
  components TestP;
  components MainC;

  TestP.Boot -> MainC;
  
  // This application supports IPv6 networking on the RF1A using
  // TinyOS Ieee154 packets
  components OipLinkLayerC;
  TestP.Ieee154Control -> OipLinkLayerC;
  TestP.Ieee154Nic -> OipLinkLayerC;

  // Derive a link layer short address for the node from its ODI,
  // placing it in PAN 2 (IEEE154)
  components new Ieee154OdiAddressC(OSIAN_ULA_SUBNET_IEEE154);
  MainC.SoftwareInit -> Ieee154OdiAddressC;

  // Assign a ULA global IPv6 address to the IEEE154 interface
  components new Ipv6SaaOsianSubnetC(OSIAN_ULA_SUBNET_IEEE154) as Ipv6SaaIeee154C;
  Ipv6SaaIeee154C.NetworkInterface -> OipLinkLayerC;

  // Allocate a UDP socket for communication with the gateway machine
  components new Udp6SocketC() as GatewayUdpC;
  TestP.GatewaySocket -> GatewayUdpC;
  TestP.GatewayDatagram -> GatewayUdpC;

  // Allocate a UDP socket for communication with the application.
  components new Udp6SocketC() as ApplicationUdpC;
  TestP.ApplicationSocket -> ApplicationUdpC;
  TestP.ApplicationDatagram -> ApplicationUdpC;

  // Provide a clock
  components LocalTimeMilliC;
  TestP.LocalTime_ms -> LocalTimeMilliC;

  // Provide an alarm for periodic application events
  components new MuxAlarmMilli16C() as ApplicationAlarm_bmsC;
  TestP.ApplicationAlarm_bms -> ApplicationAlarm_bmsC;

  // Provide an alarm for periodic gateway events
  // TODO: This should be a trickle timer
  components new MuxAlarmMilli16C() as GatewayAlarm_bmsC;
  TestP.GatewayAlarm_bms -> GatewayAlarm_bmsC;

  components LedC;
  TestP.TxAppLed -> LedC.Green;
  TestP.RxAppLed -> LedC.Red;
  TestP.GatewayLed -> LedC.Blue;

#if BUILD_FOR_GATEWAY
  // Link in a PPP daemon that supports IPv6
  components PppIpv6DaemonC as PppDaemonC;
  TestP.PppControl -> PppDaemonC; // Start and stop the daemon
  TestP.PppNic -> PppDaemonC;     // Detect when the link is up
  TestP.PppRemoteIid -> PppDaemonC.RemoteIid; // Determine the IID of the remote end of the link
#endif /* BUILD_FOR_GATEWAY */

#if 0
  // For giggles, add echo and ping support
  components Icmp6EchoRequestC;
  components Udp6EchoC;
#endif

#if BUILD_FOR_GATEWAY
#if 0
  components PppPrintfC;
  PppPrintfC.Ppp -> PppDaemonC;
  PppDaemonC.PppProtocol[PppPrintfC.Protocol] -> PppPrintfC;
#endif
#else /* BUILD_FOR_GATEWAY */
  components SerialPrintfC;
#endif /* BUILD_FOR_GATEWAY */
}
