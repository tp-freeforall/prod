#include "ppp.h"

configuration TestAppC {
} implementation {
  components TestP;

  components MainC;
  TestP.Boot -> MainC;

  components Ipv6Ieee154C;
  TestP.Rf1aNicControl -> Ipv6Ieee154C;
  TestP.Rf1aNic -> Ipv6Ieee154C;

  components NetworkInterfacesC;
  TestP.WhiteboxNetworkInterfaces -> NetworkInterfacesC;
 
#include <unittest/config_impl.h>
}


