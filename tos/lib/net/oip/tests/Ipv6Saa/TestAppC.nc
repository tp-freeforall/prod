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

  components new Ipv6SaaStaticC();
  Ipv6SaaStaticC.NetworkInterface -> NicAC;
  TestP.Ipv6Saa -> Ipv6SaaStaticC;
  TestP.WhiteboxIpv6Saa -> Ipv6SaaStaticC;

  components Ipv6C;
  TestP.AddressFamily -> Ipv6C;

  components NetworkInterfacesC;
  TestP.WhiteboxNetworkInterfaces -> NetworkInterfacesC;
  
  components LocalTimeSecondC;
  TestP.LocalTime_sec -> LocalTimeSecondC;
  TestP.ControlLocalTime_sec -> LocalTimeSecondC.GetSet;

#include <unittest/config_impl.h>
}
