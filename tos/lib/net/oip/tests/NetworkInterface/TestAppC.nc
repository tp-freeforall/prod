#include <netinet/in.h>

configuration TestAppC {
} implementation {
  components TestP;

  components MainC;
  TestP.Boot -> MainC;

  components new NetworkInterfaceC() as NicAC;
  components NicASpecificP;
  NicASpecificP.NetworkInterface -> NicAC;
  NicAC.NetworkLinkInterface -> NicASpecificP;
  NicAC.NetworkInterfaceIdentifier -> NicASpecificP;
  TestP.NicA -> NicAC;
  TestP.NicASpecific -> NicASpecificP;
  MainC.SoftwareInit -> NicASpecificP;

  components new NetworkInterfaceC() as NicNonSpecificC;
  TestP.NicNonSpecific -> NicNonSpecificC;

  components NetworkInterfacesC;
  TestP.WhiteboxNetworkInterfaces -> NetworkInterfacesC;

  components Ipv6C;

  components AddressFamiliesC;
  TestP.AddressFamilies -> AddressFamiliesC;

#include <unittest/config_impl.h>
}
