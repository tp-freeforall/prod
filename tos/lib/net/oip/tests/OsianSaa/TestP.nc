#include <stdio.h>
#include "Ipv6Saa.h"
#include <netinet/in.h>

module TestP {
  uses {
    interface Boot;
    interface Ipv6Saa;
    interface NetworkInterface as NicA;
    interface WhiteboxNetworkInterfaces;
    interface AddressFamilies;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

  uint8_t prefix_osian64[] = { 0xfd, 0x41, 0x42, 0x42, 0x0e, 0x88, 0x12, 0x34 };

  event void NicA.interfaceState (oip_nic_state_t state) { }

  event void Ipv6Saa.prefixChange (const uint8_t* prefix,
                                   uint8_t prefix_length_bits,
                                   const struct sockaddr_in6* addr,
                                   Ipv6SaaLeaseState_e lease_state)
  {
  }

  void testNicStateChange ()
  {
    union {
      struct sockaddr sa;
      struct sockaddr_in6 s6;
    } address;
    const uint8_t* iid = call NicA.interfaceIdentifier();
    uint8_t iid_length_bits = call NicA.interfaceIdentifierLength_bits();
    uint8_t iid_length_octets = (iid_length_bits + 7) / 8;
    const struct sockaddr* const* nic_addresses = call WhiteboxNetworkInterfaces.addresses(call NicA.id());

    memset(&address, 0, sizeof(address));
    address.s6.sin6_family = AF_INET6;
    memcpy(address.s6.sin6_addr.s6_addr, prefix_osian64, 8);
    memcpy(address.s6.sin6_addr.s6_addr + 8, iid, iid_length_octets);

    ASSERT_TRUE(! (IFF_UP & call NicA.getInterfaceState()));
    ASSERT_EQUAL_PTR(0, nic_addresses[0]);

    call NicA.setInterfaceState(IFF_UP | call NicA.getInterfaceState());
    ASSERT_TRUE(0 != nic_addresses[1]);
    ASSERT_TRUE(call AddressFamilies.addressEqual(&address.sa, nic_addresses[1]));
  }


  event void Boot.booted () {
    testNicStateChange();
    ALL_TESTS_PASSED();
  }
}
