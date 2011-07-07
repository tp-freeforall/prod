#include "ppp.h"

/** Basic UDP echo server.
 *
 * See the associated README.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
configuration TestAppC {
} implementation {
  components TestP;

  components MainC;
  TestP.Boot -> MainC;

  components PppIpv6DaemonC as PppDaemonC;
  TestP.Ppp -> PppDaemonC;

#if WITH_PRINTF
  components PppPrintfC;
  PppPrintfC.Ppp -> PppDaemonC;
  PppDaemonC.PppProtocol[PppPrintfC.Protocol] -> PppPrintfC;
#endif /* WITH_PRINTF */

  components Icmp6EchoRequestC;
  components Udp6EchoC;

}


