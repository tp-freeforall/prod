#include "ppp.h"

configuration TestAppC {
} implementation {
  components TestP;

  components MainC;
  TestP.Boot -> MainC;

  components PppIpv6DaemonC as PppDaemonC;
  TestP.Ppp -> PppDaemonC;
  TestP.RemoteIid -> PppDaemonC;
  TestP.PppNic -> PppDaemonC;

  components DisplayCodeC;
  PppDaemonC.DisplayCodeLcpState -> DisplayCodeC.DisplayCode[DISPLAYCODE_LCP];

  components PppIpv6C;
  PppIpv6C.DisplayCodeLcpState -> DisplayCodeC.DisplayCode[DISPLAYCODE_IPV6LCP];

  components PppPrintfC;
  PppPrintfC.Ppp -> PppDaemonC;
  PppDaemonC.PppProtocol[PppPrintfC.Protocol] -> PppPrintfC;
  
}
