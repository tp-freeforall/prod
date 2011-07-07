#include "Ipv6Saa.h"
interface WhiteboxIpv6Saa {
  command uint8_t prefixesPerNic ();
  command struct ipv6SaaPrefixInfo_t_** prefixes ();
}
