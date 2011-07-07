#include <stdio.h>
#include "Ipv6Saa.h"
#include <netinet/in.h>

module TestP {
  uses {
    interface Boot;
    interface Ipv6Saa;
    interface NetworkInterface as NicA;
    interface WhiteboxNetworkInterfaces;
    interface AddressFamily;
    interface WhiteboxIpv6Saa;
    interface LocalTime<TSecond> as LocalTime_sec;
    interface GetSet<uint32_t> as ControlLocalTime_sec;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

  enum {
    MAX_SAA_EVENTS = 4,
    EPOCH_SEC = 1423,
    INFINITE_LIFETIME = ~0UL,
    VALID_LIFETIME = 3600,
    PREFERRED_LIFETIME = 1800,
  };

  typedef struct saa_event_t {
      const uint8_t * prefix;
      uint8_t prefix_length_bits;
      const struct sockaddr_in6* addr;
      Ipv6SaaLeaseState_e lease_state;
  } saa_event_t;

  saa_event_t events[MAX_SAA_EVENTS];
  int nevents;

  uint8_t prefix_osian64[] = { 0xfd, 0x41, 0x42, 0x42, 0x0e, 0x88, 0x00, 0x01 };
  uint8_t prefix_doc128[] = { 0x20, 0x01, 0x0d, 0xb8, 0x00, 0x00, 0x00, 0xA5,
                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };

  uint8_t ppn;
  struct ipv6SaaPrefixInfo_t_** prefixes;

  event void NicA.interfaceState (oip_nic_state_t state) { }

  event void Ipv6Saa.prefixChange (const uint8_t* prefix,
                                   uint8_t prefix_length_bits,
                                   const struct sockaddr_in6* addr,
                                   Ipv6SaaLeaseState_e lease_state)
  {
    saa_event_t* ep;

    if (nevents < MAX_SAA_EVENTS) {
      ep = events + nevents++;
      ep->prefix = prefix;
      ep->prefix_length_bits = prefix_length_bits;
      ep->addr = addr;
      ep->lease_state = lease_state;
    }
  }

  void testNicStateChange ()
  {
    error_t rc;
    struct ipv6SaaPrefixInfo_t_* pip;
    struct sockaddr_in6 sa6;
    struct sockaddr* sap = (struct sockaddr*)&sa6;
    const struct sockaddr* esap;
    const struct sockaddr* const* nic_addresses = call WhiteboxNetworkInterfaces.addresses(call NicA.id());

    nevents = 0;
    
    memset(&sa6, 0, sizeof(sa6));
    sa6.sin6_family = AF_INET6;
    memcpy(sa6.sin6_addr.s6_addr, prefix_osian64, 8);
    memcpy(sa6.sin6_addr.s6_addr + 8, call NicA.interfaceIdentifier(), (call NicA.interfaceIdentifierLength_bits() + 7) / 8);

    ASSERT_TRUE(! (IFF_UP & call NicA.getInterfaceState()));
    ASSERT_EQUAL_PTR(0, nic_addresses[0]);

    rc = call Ipv6Saa.definePrefix(prefix_osian64, 64, VALID_LIFETIME, PREFERRED_LIFETIME);
    ASSERT_EQUAL(SUCCESS, rc);
    pip = prefixes[0];
    ASSERT_TRUE(0 != pip);

    ASSERT_EQUAL(0, nevents);

    call NicA.setInterfaceState(IFF_UP | call NicA.getInterfaceState());
    ASSERT_EQUAL(1, nevents);
    ASSERT_EQUAL(SAALS_preferred, events[0].lease_state);
    esap = (const struct sockaddr*)events[0].addr;
    ASSERT_TRUE(call AddressFamily.addressEqual(sap, esap));

    nevents = 0;
    call NicA.setInterfaceState((~ IFF_UP) & call NicA.getInterfaceState());
    ASSERT_EQUAL(1, nevents);
    ASSERT_EQUAL(SAALS_nicDown, events[0].lease_state);
    esap = (const struct sockaddr*)events[0].addr;
    ASSERT_TRUE(call AddressFamily.addressEqual(sap, esap));
    ASSERT_EQUAL_PTR(0, nic_addresses[0]);

    rc = call Ipv6Saa.definePrefix(prefix_osian64, 64, 0UL, 0UL);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL_PTR(0, prefixes[0]);
  }

  void testRegisterAddressWhileUp ()
  {
    struct sockaddr_in6 sa6;
    struct sockaddr* sap = (struct sockaddr*)&sa6;
    const struct sockaddr* esap;
    const struct sockaddr* const* nic_addresses = call WhiteboxNetworkInterfaces.addresses(call NicA.id());
    struct ipv6SaaPrefixInfo_t_* pip;
    uint8_t link_local_prefix[] = { 0xfe, 0x80 };
    error_t rc;

    nevents = 0;
    
    memset(&sa6, 0, sizeof(sa6));
    sa6.sin6_family = AF_INET6;
    memcpy(sa6.sin6_addr.s6_addr, prefix_osian64, 8);
    memcpy(sa6.sin6_addr.s6_addr + 8, call NicA.interfaceIdentifier(), (call NicA.interfaceIdentifierLength_bits() + 7) / 8);

    ASSERT_TRUE(! (IFF_UP & call NicA.getInterfaceState()));
    ASSERT_EQUAL_PTR(0, nic_addresses[0]);
    ASSERT_EQUAL_PTR(0, prefixes[0]);

    ASSERT_EQUAL(0, nevents);
    call NicA.setInterfaceState(IFF_UP | call NicA.getInterfaceState());
    ASSERT_EQUAL(0, nevents);
    ASSERT_TRUE(0 != nic_addresses[0]);
    ASSERT_EQUAL_PTR(nic_addresses[0], call NicA.locatePrefixBinding(AF_INET6, link_local_prefix, 10));
    ASSERT_EQUAL_PTR(0, prefixes[0]);

#if (4 < __GNUC__) || ((4 == __GNUC__) && (4 < __GNUC_MINOR__)) || ((4 == __GNUC__) && (4 ==__GNUC_MINOR__) && (4 <= __GNUC_PATCHLEVEL__))
    /* This code relies on functionality that causes a compiler bug
     * prior to a patch introduced for mspgcc4 at the time GCC 4.4.4
     * was supported. */
    rc = call Ipv6Saa.definePrefix(prefix_osian64, 64, VALID_LIFETIME, PREFERRED_LIFETIME);
    ASSERT_EQUAL(SUCCESS, rc);

    pip = prefixes[0];
    ASSERT_TRUE(0 != pip);
    ASSERT_EQUAL_PTR(pip->address, events[0].addr);

    ASSERT_EQUAL(1, nevents);
    ASSERT_EQUAL(SAALS_preferred, events[0].lease_state);
    esap = (const struct sockaddr*)events[0].addr;
    ASSERT_TRUE(call AddressFamily.addressEqual(sap, esap));
    ASSERT_TRUE(call AddressFamily.addressEqual(esap, nic_addresses[1]));

    /* Repeating the assignment should not produce a new prefix binding */
    rc = call Ipv6Saa.definePrefix(prefix_osian64, 64, VALID_LIFETIME, PREFERRED_LIFETIME);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL(1, nevents);
#else
    printf("***WARNING: Incomplete test (not testing code that produces compiler error)\r\n");
#endif
  }

  void testRegisterAddressWhileDown ()
  {
    error_t rc;
    struct ipv6SaaPrefixInfo_t_* pip;
    struct ipv6SaaPrefixInfo_t_* pip2;
    uint8_t not_doc[8];
    
    ASSERT_EQUAL_PTR(0, prefixes[0]);
    ASSERT_EQUAL(0, nevents);
    ASSERT_TRUE(! (IFF_UP & call NicA.getInterfaceState()));

    rc = call Ipv6Saa.definePrefix(prefix_osian64, 64, VALID_LIFETIME, PREFERRED_LIFETIME);
    ASSERT_EQUAL(SUCCESS, rc);
    pip = prefixes[0];
    ASSERT_TRUE(0 != pip);
    ASSERT_EQUAL(64, pip->prefix_length_bits);
    ASSERT_TRUE(0 == memcmp(pip->prefix, prefix_osian64, sizeof(prefix_osian64)));
    ASSERT_EQUAL(EPOCH_SEC + VALID_LIFETIME, pip->valid_timeout);
    ASSERT_EQUAL(EPOCH_SEC + PREFERRED_LIFETIME, pip->preferred_timeout);

    ASSERT_TRUE(1 < ppn);
    ASSERT_EQUAL_PTR(0, prefixes[1]);

    /* Updated times should find existing record */
    rc = call Ipv6Saa.definePrefix(prefix_osian64, 64, INFINITE_LIFETIME, VALID_LIFETIME);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL_PTR(pip, prefixes[0]);
    ASSERT_EQUAL_PTR(0, prefixes[1]);
    ASSERT_EQUAL_32(INFINITE_LIFETIME, pip->valid_timeout);
    ASSERT_EQUAL_32(EPOCH_SEC + VALID_LIFETIME, pip->preferred_timeout);
    
    /* Add a new record */
    rc = call Ipv6Saa.definePrefix(prefix_doc128, 64, INFINITE_LIFETIME, INFINITE_LIFETIME);
    ASSERT_EQUAL(SUCCESS, rc);
    pip2 = prefixes[1];
    ASSERT_TRUE(0 != pip2);

    rc = call Ipv6Saa.definePrefix(prefix_doc128, 32, INFINITE_LIFETIME, INFINITE_LIFETIME);
    ASSERT_EQUAL(ENOMEM, rc);
    
    rc = call Ipv6Saa.definePrefix(prefix_osian64, 64, 0UL, 0UL);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL_PTR(pip2, prefixes[0]);
    ASSERT_EQUAL(pip2->prefix_length_bits, 64);
    ASSERT_EQUAL_PTR(0, prefixes[1]);

    /* Define with zero lifetime does not add */
    rc = call Ipv6Saa.definePrefix(prefix_doc128, 96, 0UL, 0UL);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL_PTR(pip2, prefixes[0]);
    ASSERT_EQUAL(pip2->prefix_length_bits, 64);
    ASSERT_EQUAL_PTR(0, prefixes[1]);

    /* Define with non-zero lifetime does add (new prefix length, but within reserved pool length) */
    rc = call Ipv6Saa.definePrefix(prefix_doc128, 60, VALID_LIFETIME, PREFERRED_LIFETIME);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL_PTR(pip2, prefixes[0]);
    pip = prefixes[1];
    ASSERT_TRUE(0 != pip);
    ASSERT_EQUAL(60, pip->prefix_length_bits);
    ASSERT_EQUAL_32(EPOCH_SEC + VALID_LIFETIME, pip->valid_timeout);

    memcpy(not_doc, prefix_doc128, sizeof(not_doc));
    not_doc[sizeof(not_doc)-1] ^= 0x0F;

    /* Match fails to find existing with non-aligned prefix, adds new */
    rc = call Ipv6Saa.definePrefix(not_doc, 60, PREFERRED_LIFETIME, PREFERRED_LIFETIME);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL_32(EPOCH_SEC + PREFERRED_LIFETIME, pip->valid_timeout);

    /* Match succeeds with non-aligned prefix */
    rc = call Ipv6Saa.definePrefix(not_doc, 60, VALID_LIFETIME, PREFERRED_LIFETIME);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL_32(EPOCH_SEC + VALID_LIFETIME, pip->valid_timeout);

    /* Match fails with aligned prefix with mismatched value */
    rc = call Ipv6Saa.definePrefix(not_doc, 64, PREFERRED_LIFETIME, PREFERRED_LIFETIME);
    ASSERT_EQUAL(ENOMEM, rc);

    not_doc[sizeof(not_doc)-1] ^= 0xF0;
    rc = call Ipv6Saa.definePrefix(not_doc, 60, PREFERRED_LIFETIME, PREFERRED_LIFETIME);
    ASSERT_EQUAL(ENOMEM, rc);

    /* Reset everything */
    rc = call Ipv6Saa.definePrefix(pip2->prefix, pip2->prefix_length_bits, 0UL, 0UL);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL_PTR(pip, prefixes[0]);
    ASSERT_EQUAL_PTR(0, prefixes[1]);

    rc = call Ipv6Saa.definePrefix(pip->prefix, pip->prefix_length_bits, 0UL, 0UL);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL_PTR(0, prefixes[0]);
  }

  // match non-byte
  // empty
  // no space available 

  void testInitialState ()
  {
    int i;

    ASSERT_EQUAL(OIP_SAA_PREFIXES_PER_NIC, ppn);
    ASSERT_TRUE(0 != prefixes);
    for (i = 0; i < ppn; ++i) {
      ASSERT_EQUAL_PTR(0, prefixes[i]);
    }

    ASSERT_EQUAL(EPOCH_SEC, call LocalTime_sec.get());
  }

  event void Boot.booted () {
    ppn = call WhiteboxIpv6Saa.prefixesPerNic();
    prefixes = call WhiteboxIpv6Saa.prefixes();
    call ControlLocalTime_sec.set(EPOCH_SEC);

    testInitialState();
    testRegisterAddressWhileDown();
    testNicStateChange();
    testRegisterAddressWhileUp();
    ALL_TESTS_PASSED();
  }
}
