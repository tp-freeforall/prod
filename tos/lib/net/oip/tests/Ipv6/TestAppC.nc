configuration TestAppC {
} implementation {
  components TestP;
  components MainC;

  TestP.Boot -> MainC;
  
  components new Udp6SocketC();
  TestP.UdpSocket -> Udp6SocketC;

  components new NetworkInterfaceC();
  TestP.NetworkInterface -> NetworkInterfaceC;

  components NetworkInterfacesC;
  TestP.WhiteboxNetworkInterfaces -> NetworkInterfacesC;

  components AddressFamiliesC;
  TestP.AddressFamilies -> AddressFamiliesC;

#include <unittest/config_impl.h>
}
