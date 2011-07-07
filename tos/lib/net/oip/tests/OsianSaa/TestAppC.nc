configuration TestAppC {
} implementation {
  components TestP;
  components MainC;

  TestP.Boot -> MainC;
  
  components new NetworkInterfaceC() as NicAC;
  components NicASpecificP;
  NicASpecificP.NetworkInterface -> NicAC;
  NicAC.NetworkInterfaceIdentifier -> NicASpecificP;
  MainC.SoftwareInit -> NicASpecificP;
  TestP.NicA -> NicAC;

  components AddressFamiliesC;
  TestP.AddressFamilies -> AddressFamiliesC;

  components new Ipv6SaaOsianSubnetC(0x1234);
  Ipv6SaaOsianSubnetC.NetworkInterface -> NicAC;

  components NetworkInterfacesC;
  TestP.WhiteboxNetworkInterfaces -> NetworkInterfacesC;
  
#include <unittest/config_impl.h>
}
