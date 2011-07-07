#include <net/osian.h>
#include <netinet/in.h>

configuration TestAppC {
} implementation {
  components TestP;
  components MainC;

  TestP.Boot -> MainC;
  
  // Link in the Radio NIC support
  components OipLinkLayerC;
  TestP.RadioControl -> OipLinkLayerC;
  TestP.RadioNic -> OipLinkLayerC;

#include "OipLinkLayer.h"

#if OIP_LINK_LAYER == OIP_LINK_LAYER_IEEE154
  // Provide access to the IEEE154 link layer address assignment
  components Ieee154AddressC;
  TestP.Ieee154Address -> Ieee154AddressC;
#endif

  // Link in the PPP NIC support
  components PppIpv6DaemonC as PppDaemonC;
  TestP.PppControl -> PppDaemonC; // Start and stop the daemon
  TestP.PppNic -> PppDaemonC;     // Detect when the link is up
  TestP.PppLocalIid -> PppDaemonC.LocalIid; // Determine the IID of the local end of the link
  TestP.PppRemoteIid -> PppDaemonC.RemoteIid; // Determine the IID of the remote end of the link

  // Raw socket used for operations
  components new IpSocketC(AF_INET6, SOCK_RAW, IPPROTO_RAW);
  TestP.IpSocket -> IpSocketC;
  TestP.IpSocketMsg -> IpSocketC;

  // Reference protocols that we will bridge.  Without this, the IP stack
  // won't recognize the header and will ignore them.
  components Udp6C;
  components Icmp6C;

  components LedC;
  TestP.PppLed -> LedC.Blue;
  TestP.PppToRadioLed -> LedC.Red;
  TestP.RadioToPppLed -> LedC.Green;

  components PppPrintfC;
  PppPrintfC.Ppp -> PppDaemonC;
  PppDaemonC.PppProtocol[PppPrintfC.Protocol] -> PppPrintfC;

  // Note: Network services like Icmp6EchoRequestC rely on the IPv6
  // stack to filter out packets not addressed to the target node.
  // Both the PPP and Radio NIC interfaces are set to IFF_PROMISC.
  // As a consequence all such filtering is ignored, and both this
  // gateway application and the intended node are likely to respond.
}
