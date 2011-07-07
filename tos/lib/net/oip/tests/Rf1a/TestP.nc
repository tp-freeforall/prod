#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

module TestP {
  uses {
    interface Boot;
    interface NetworkInterface as Rf1aNic;
    interface SplitControl as Rf1aNicControl;
    interface WhiteboxNetworkInterfaces;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

  int nevents;
  event void Rf1aNic.interfaceState (oip_nic_state_t state) { ++nevents; }
  event void Rf1aNicControl.startDone (error_t error) { }
  event void Rf1aNicControl.stopDone (error_t error) { }

  void testLinkLocalAddress ()
  {
    error_t rc;
    const struct sockaddr* const* nic_addresses = call WhiteboxNetworkInterfaces.addresses(call Rf1aNic.id());
    uint8_t link_local_prefix[] = { 0xfe, 0x80 };

    ASSERT_TRUE(! (IFF_UP & call Rf1aNic.getInterfaceState()));
    ASSERT_EQUAL_PTR(0, nic_addresses[0]);

    call Rf1aNic.setInterfaceState(IFF_UP | call Rf1aNic.getInterfaceState());
    ASSERT_EQUAL(1, nevents);
    ASSERT_TRUE(0 != nic_addresses[0]);
    //printf("LLA: %s\r\n", getnameinfo(nic_addresses[0]));
    ASSERT_EQUAL_PTR(nic_addresses[0], call Rf1aNic.locatePrefixBinding(AF_INET6, link_local_prefix, 10));

    /* Verify the generated IID has bit 7 set indicating a universal
     * address in modified EUI-64 format */
    ASSERT_EQUAL(0x02, 0x02 & ((struct sockaddr_in6*)nic_addresses[0])->sin6_addr.s6_addr[8]);

    call Rf1aNic.setInterfaceState((~ IFF_UP) & call Rf1aNic.getInterfaceState());
    ASSERT_EQUAL_PTR(0, nic_addresses[0]);
  }

  event void Boot.booted()
  {
    testLinkLocalAddress();
    ALL_TESTS_PASSED();
  }
}
