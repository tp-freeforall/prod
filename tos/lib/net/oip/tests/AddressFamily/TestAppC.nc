configuration TestAppC {
} implementation {
  components TestP;
  components MainC;

  TestP.Boot -> MainC;
  
  components Ipv6C;
  TestP.AfInet6 -> Ipv6C.AddressFamily;

  components AddressFamiliesC;
  TestP.AddressFamilies -> AddressFamiliesC;

#include <unittest/config_impl.h>
}
