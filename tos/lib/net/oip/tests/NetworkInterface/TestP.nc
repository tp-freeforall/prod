#include <stdio.h>
#include <net/if.h>
#include <netinet/in.h>
#include <arpa/inet.h>

module TestP {
  uses {
    interface Boot;
    interface NetworkInterface as NicA;
    interface NicASpecific;
    interface NetworkInterface as NicNonSpecific;
    interface WhiteboxNetworkInterfaces;
    interface AddressFamilies;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

  uint8_t nicAChangeCount_;
  event void NicA.interfaceState (oip_nic_state_t state) { ++nicAChangeCount_; }
  event void NicNonSpecific.interfaceState (oip_nic_state_t state) { }

  enum {
    NicA_id1 = 1,
    NicNonSpecific_id1 = 2,
    NoSuchNic_id1 = 3,
  };

  typedef union sockaddr_u {
      struct sockaddr sa;
      struct sockaddr_in6 s6;
  } sockaddr_u;

  /* One link-local address, a bunch of unicast addresses */
  sockaddr_u addresses_[OIP_AF_INET6_POOL_SIZE];

  sockaddr_u groups_[OIP_GROUPS_PER_NIC];

  void testNicId ()
  {
    ASSERT_EQUAL(NicA_id1, call NicA.id());
    ASSERT_EQUAL(NicNonSpecific_id1, call NicNonSpecific.id());
    ASSERT_TRUE((call WhiteboxNetworkInterfaces.numNics()) <= (NoSuchNic_id1-1));
  }

  void initializeAddresses ()
  {
    int num_addresses = call WhiteboxNetworkInterfaces.addressesPerNic();
    int i;

    ASSERT_TRUE(num_addresses < OIP_AF_INET6_POOL_SIZE);
    for (i = 0; i < OIP_AF_INET6_POOL_SIZE; ++i) {
      struct sockaddr_in6* sap = &addresses_[i].s6;
      struct in6_addr* iap = &sap->sin6_addr;

      memset(sap, 0, sizeof(*sap));
      sap->sin6_family = AF_INET6;
      if (0 == i) {
        iap->s6_addr[0] = 0xfe;
        iap->s6_addr[1] = 0x80;
        iap->s6_addr[15] = 1+i;
      } else {
        iap->s6_addr[0] = 0x20;
        iap->s6_addr[1] = 0x01;
        iap->s6_addr[2] = 0x0d;
        iap->s6_addr[3] = 0xb8;
        iap->s6_addr[15] = 1+i;
      }
      //printf("%d: %s\r\n", i, inet_ntop(AF_INET6, iap));
    }

    for (i = 0; i < OIP_GROUPS_PER_NIC; ++i) {
      struct sockaddr_in6* sap = &groups_[i].s6;
      struct in6_addr* iap = &sap->sin6_addr;

      memset(sap, 0, sizeof(*sap));
      sap->sin6_family = AF_INET6;
      iap->s6_addr[0] = 0xff;
      iap->s6_addr[1] = 1 + i;
      iap->s6_addr[15] = 1;
    }
  }
  
  void testLinkAddress ()
  {
    error_t rc;
    const struct sockaddr* lap;
    
    ASSERT_EQUAL_PTR(0, call WhiteboxNetworkInterfaces.linkAddress(NicA_id1));
    ASSERT_TRUE(0 == call NicA.getLinkAddress());

    rc = call NicA.setLinkAddress(&addresses_[0].sa);
    ASSERT_EQUAL(SUCCESS, rc);
    lap = call NicA.getLinkAddress();
    ASSERT_TRUE(0 != lap);
    ASSERT_TRUE(lap != &addresses_[0].sa);
    ASSERT_TRUE(call AddressFamilies.addressEqual(lap, &addresses_[0].sa));
    ASSERT_EQUAL_PTR(lap, call WhiteboxNetworkInterfaces.linkAddress(NicA_id1));

    rc = call NicA.setLinkAddress(&addresses_[1].sa);
    ASSERT_EQUAL(EALREADY, rc);
    ASSERT_EQUAL_PTR(lap, call WhiteboxNetworkInterfaces.linkAddress(NicA_id1));

    rc = call NicA.setLinkAddress(0);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL_PTR(0, call WhiteboxNetworkInterfaces.linkAddress(NicA_id1));
    ASSERT_TRUE(0 == call NicA.getLinkAddress());
  }


  void testAddressInitialization ()
  {
    int num_nic = call WhiteboxNetworkInterfaces.numNics();
    int ni;
    int num_addresses = call WhiteboxNetworkInterfaces.addressesPerNic();
    int ai;

    for (ni = 1; ni <= num_nic; ++ni) {
      const struct sockaddr* const* addrs = call WhiteboxNetworkInterfaces.addresses(ni);
      ASSERT_TRUE(0 != addrs);
      for (ai = 0; ai < num_addresses; ++ai) {
        ASSERT_EQUAL_PTR(0, addrs[ai]);
      }
    }
  }

  void itestLocatePrefixBinding ()
  {
    uint8_t link_local_prefix[] = { 0xfe, 0x83 };
    const struct sockaddr* pbp;
    struct sockaddr_in6* s6p;
    struct sockaddr* sap;

    s6p = &addresses_[0].s6;
    sap = &addresses_[0].sa;
    ASSERT_TRUE(call AddressFamilies.addressPrefixMatch(sap, link_local_prefix, 10));
    pbp = call NicA.locatePrefixBinding(AF_INET6, link_local_prefix, 10);
    ASSERT_TRUE(0 != pbp);
    ASSERT_TRUE(call AddressFamilies.addressEqual(sap, pbp));
    ASSERT_EQUAL_PTR(0, call NicA.locatePrefixBinding(AF_UNSPEC, link_local_prefix, 10));
    ASSERT_EQUAL_PTR(0, call NicA.locatePrefixBinding(AF_INET6, link_local_prefix, 16));

    // a1 = 2001:db8::2
    // a2 = 2001:db8::3
    // a3 = 2001:db8::4
    ASSERT_TRUE(call AddressFamilies.addressPrefixMatch(&addresses_[2].sa, addresses_[2].s6.sin6_addr.s6_addr, 128));
    ASSERT_TRUE(! call AddressFamilies.addressPrefixMatch(&addresses_[2].sa, addresses_[4].s6.sin6_addr.s6_addr, 128));

    /* Through bit 125, A1 A2 A4 indistinguishable */
    pbp = call NicA.locatePrefixBinding(AF_INET6, addresses_[2].s6.sin6_addr.s6_addr, 125);
    ASSERT_TRUE(0 != pbp);
    ASSERT_TRUE(call AddressFamilies.addressEqual(&addresses_[1].sa, pbp));
    pbp = call NicA.locatePrefixBinding(AF_INET6, addresses_[4].s6.sin6_addr.s6_addr, 125);
    ASSERT_TRUE(0 != pbp);
    ASSERT_TRUE(call AddressFamilies.addressEqual(&addresses_[1].sa, pbp));

    /* At bit 126, A4 doesn't match A1 or A2 */
    pbp = call NicA.locatePrefixBinding(AF_INET6, addresses_[2].s6.sin6_addr.s6_addr, 126);
    ASSERT_TRUE(0 != pbp);
    ASSERT_TRUE(call AddressFamilies.addressEqual(&addresses_[1].sa, pbp));
    pbp = call NicA.locatePrefixBinding(AF_INET6, addresses_[3].s6.sin6_addr.s6_addr, 126);
    ASSERT_TRUE(0 != pbp);
    ASSERT_TRUE(call AddressFamilies.addressEqual(&addresses_[3].sa, pbp));

    pbp = call NicA.locatePrefixBinding(AF_INET6, addresses_[2].s6.sin6_addr.s6_addr, 127);
    ASSERT_TRUE(0 != pbp);
    ASSERT_TRUE(call AddressFamilies.addressEqual(&addresses_[1].sa, pbp));
    pbp = call NicA.locatePrefixBinding(AF_INET6, addresses_[3].s6.sin6_addr.s6_addr, 127);
    ASSERT_TRUE(0 != pbp);
    ASSERT_TRUE(call AddressFamilies.addressEqual(&addresses_[3].sa, pbp));

    /* At bit 128 all three are distinct */
    pbp = call NicA.locatePrefixBinding(AF_INET6, addresses_[2].s6.sin6_addr.s6_addr, 128);
    ASSERT_TRUE(0 != pbp);
    ASSERT_TRUE(call AddressFamilies.addressEqual(&addresses_[2].sa, pbp));
    pbp = call NicA.locatePrefixBinding(AF_INET6, addresses_[3].s6.sin6_addr.s6_addr, 128);
    ASSERT_TRUE(0 != pbp);
    ASSERT_TRUE(call AddressFamilies.addressEqual(&addresses_[3].sa, pbp));
  }

  void testJoinLeave ()
  {
    const struct sockaddr* const* addrs = call WhiteboxNetworkInterfaces.addresses(NicA_id1);
    int num_groups = call WhiteboxNetworkInterfaces.groupsPerNic();
    const struct sockaddr* const* groups = call WhiteboxNetworkInterfaces.groups(NicA_id1);
    error_t rc;
    
    ASSERT_TRUE(addrs != groups);
    ASSERT_TRUE(2 <= num_groups);
    ASSERT_EQUAL_PTR(0, groups[0]);
    rc = call NicA.joinGroup(&groups_[0].sa);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_TRUE(0 != groups[0]);
    ASSERT_TRUE(call AddressFamilies.addressEqual(&groups_[0].sa, groups[0]));
    ASSERT_EQUAL_PTR(0, groups[1]);
    rc = call NicA.joinGroup(&groups_[1].sa);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_TRUE(0 != groups[0]);
    ASSERT_TRUE(call AddressFamilies.addressEqual(&groups_[0].sa, groups[0]));
    ASSERT_TRUE(0 != groups[1]);
    ASSERT_TRUE(call AddressFamilies.addressEqual(&groups_[1].sa, groups[1]));
    ASSERT_EQUAL_PTR(0, groups[2]);
    rc = call NicA.leaveGroup(&groups_[2].sa);
    ASSERT_EQUAL(EINVAL, rc);
    rc = call NicA.leaveGroup(&groups_[0].sa);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_TRUE(0 != groups[0]);
    ASSERT_TRUE(call AddressFamilies.addressEqual(&groups_[1].sa, groups[0]));
    ASSERT_EQUAL_PTR(0, groups[1]);
    rc = call NicA.leaveGroup(&groups_[1].sa);
    ASSERT_EQUAL(SUCCESS, rc);
    ASSERT_EQUAL_PTR(0, groups[0]);
  }

  void testBindRelease ()
  {
    int num_addresses = call WhiteboxNetworkInterfaces.addressesPerNic();
    const struct sockaddr* const* addrs = call WhiteboxNetworkInterfaces.addresses(NicA_id1);
    sockaddr_u s3c;
    struct sockaddr* sap;
    struct sockaddr_in6* s6p;
    const struct sockaddr* const* bound_addrs;
    int rc;
    int ai;

    s3c = addresses_[3];

    for (ai = 0; ai < num_addresses; ++ai) {
      sap = &addresses_[ai].sa;
      s6p = &addresses_[ai].s6;

      ASSERT_TRUE(0 != sap);

      ASSERT_TRUE(! call NicA.acceptDeliveryTo(sap));
      ASSERT_EQUAL(0, s6p->sin6_scope_id);

      ASSERT_EQUAL_PTR(0, addrs[ai]);

      rc = call NicA.bindAddress(sap);

      ASSERT_EQUAL(SUCCESS, rc);
      ASSERT_TRUE(call AddressFamilies.addressEqual(sap, addrs[ai]));
      ASSERT_EQUAL(0, s6p->sin6_scope_id);
      ASSERT_EQUAL(call NicA.id(), ((struct sockaddr_in6*)addrs[ai])->sin6_scope_id);

      ASSERT_TRUE(call NicA.acceptDeliveryTo(sap));
      
      ASSERT_TRUE((3 != ai) || call NicA.acceptDeliveryTo(&s3c.sa));

      rc = call NicA.boundAddresses(&bound_addrs);
      ASSERT_EQUAL(1+ai, rc);
      ASSERT_EQUAL_PTR(addrs[ai], bound_addrs[rc-1]);
    }

    sap = &addresses_[num_addresses].sa;
    ASSERT_TRUE(! call NicA.acceptDeliveryTo(sap));

    rc = call NicA.bindAddress(sap);
    ASSERT_EQUAL(ENOMEM, rc);
    ASSERT_TRUE(! call NicA.acceptDeliveryTo(sap));

    rc = call NicA.releaseAddress(sap);
    ASSERT_EQUAL(EINVAL, rc);
    ASSERT_TRUE(! call NicA.acceptDeliveryTo(sap));

    /* While they're assigned, test some other stuff */
    itestLocatePrefixBinding();

    for (ai = 0; ai < num_addresses; ++ai) {
      sap = &addresses_[ai].sa;
      s6p = &addresses_[ai].s6;

      ASSERT_TRUE(0 != addrs[num_addresses - 1 - ai]);
      ASSERT_TRUE(call AddressFamilies.addressEqual(sap, addrs[0]));
      rc = call NicA.releaseAddress(sap);
      ASSERT_EQUAL(SUCCESS, rc);
      ASSERT_TRUE(0 == addrs[num_addresses - 1 - ai]);

      ASSERT_TRUE(0 == s6p->sin6_scope_id);

      rc = call NicA.releaseAddress(sap);
      ASSERT_EQUAL(EINVAL, rc);

      ASSERT_TRUE(! call NicA.acceptDeliveryTo(sap));
    }
  }

  void adtHelper (int num_addresses,
                  const struct sockaddr* const* nic_addresses,
                  struct sockaddr_in6* sin6p)
  {
    struct sockaddr* saddr = (struct sockaddr*)sin6p;
    int i;
    
    for (i = 0; i < num_addresses; ++i) {
      int mi;
      bool adt;
      
      sin6p->sin6_addr.s6_addr[15] = 1+i;
      mi = call AddressFamilies.acceptDeliveryTo(saddr, NicA_id1);
      adt = call NicA.acceptDeliveryTo(saddr);
      //printf("%s %d\r\n", getnameinfo(saddr), mi);
      ASSERT_EQUAL(adt, 0 <= mi);
      if (adt) {
        if (IN6_IS_ADDR_MULTICAST(&sin6p->sin6_addr)) {
          ASSERT_TRUE(! call AddressFamilies.addressEqual(saddr, nic_addresses[mi]));
        } else {
          ASSERT_TRUE(call AddressFamilies.addressEqual(saddr, nic_addresses[mi]));
        }
      }
    }
  }

  void testAcceptDeliveryTo ()
  {
    sockaddr_u addr;
    int num_addresses = call WhiteboxNetworkInterfaces.addressesPerNic();
    error_t rc;
    int i;

    for (i = 0; i < num_addresses; ++i) {
      rc = call NicA.bindAddress(&addresses_[i].sa);
      ASSERT_EQUAL(SUCCESS, rc);
    }

    /* Sorry, this isn't a great test.  You may need to visually
     * inspect things. */
    memset(&addr, 0, sizeof(addr));
    addr.s6.sin6_family = AF_INET6;
    addr.s6.sin6_addr.s6_addr16[0] = htons(0x2001);
    addr.s6.sin6_addr.s6_addr16[1] = htons(0x0db8);
    addr.s6.sin6_addr.s6_addr[15] = 1;
    ASSERT_TRUE(! call NicA.acceptDeliveryTo(&addr.sa));
    addr.s6.sin6_addr.s6_addr[15] = 2;
    ASSERT_TRUE(call NicA.acceptDeliveryTo(&addr.sa));

    memset(&addr.s6.sin6_addr, 0, sizeof(addr.s6.sin6_addr));
    addr.s6.sin6_addr.s6_addr16[0] = htons(0xff02);
    addr.s6.sin6_addr.s6_addr[15] = 1;
    ASSERT_TRUE(call NicA.acceptDeliveryTo(&addr.sa));
    addr.s6.sin6_addr.s6_addr[15] = 2;
    ASSERT_TRUE(! call NicA.acceptDeliveryTo(&addr.sa));

    memset(&addr.s6.sin6_addr, 0, sizeof(addr.s6.sin6_addr));
    addr.s6.sin6_addr.s6_addr16[0] = htons(0xff02);
    addr.s6.sin6_addr.s6_addr16[5] = htons(1);
    addr.s6.sin6_addr.s6_addr16[6] = addresses_[1].s6.sin6_addr.s6_addr16[6];
    addr.s6.sin6_addr.s6_addr16[7] = addresses_[1].s6.sin6_addr.s6_addr16[7];
    ASSERT_TRUE(! call NicA.acceptDeliveryTo(&addr.sa));
    addr.s6.sin6_addr.s6_addr16[6] |= htons(0xFF00);
    ASSERT_TRUE(call NicA.acceptDeliveryTo(&addr.sa));

    for (i = 0; i < num_addresses; ++i) {
      rc = call NicA.releaseAddress(&addresses_[i].sa);
      ASSERT_EQUAL(SUCCESS, rc);
    }

  }

  void testInterfaceIdentifier ()
  {
    const uint8_t* iidp;
    iidp = call NicA.interfaceIdentifier();
    ASSERT_TRUE(0 != iidp);
    ASSERT_EQUAL(0xA5, *iidp);
    ASSERT_EQUAL(8, call NicA.interfaceIdentifierLength_bits());

    ASSERT_EQUAL_PTR(0, call NicNonSpecific.interfaceIdentifier());
    ASSERT_EQUAL(0, call NicNonSpecific.interfaceIdentifierLength_bits());
  }

  void testInterfaceState ()
  {
    ASSERT_EQUAL(0, call NicNonSpecific.getInterfaceState());
    ASSERT_EQUAL(0, call WhiteboxNetworkInterfaces.NetworkInterface_getInterfaceState(NicNonSpecific_id1));

    ASSERT_EQUAL(1, nicAChangeCount_); /* From the init call */
    ASSERT_EQUAL(IFF_POINTTOPOINT, call NicA.getInterfaceState());
    ASSERT_EQUAL(IFF_POINTTOPOINT, call WhiteboxNetworkInterfaces.NetworkInterface_getInterfaceState(NicA_id1));
    call NicA.setInterfaceState(IFF_UP | call NicA.getInterfaceState());
    ASSERT_EQUAL(2, nicAChangeCount_); /* From the init call */
    ASSERT_EQUAL(IFF_UP | IFF_POINTTOPOINT, call NicA.getInterfaceState());

    ASSERT_EQUAL(IFF_INVALID, call WhiteboxNetworkInterfaces.NetworkInterface_getInterfaceState(NoSuchNic_id1));
  }

  void testRxMetadata ()
  {
    uint8_t metadata;
    ASSERT_EQUAL_PTR(0, call NicA.rxMetadata());
    call NicASpecific.provideRxMetadata(&metadata);
    ASSERT_EQUAL_PTR(&metadata, call NicA.rxMetadata());
    call NicASpecific.provideRxMetadata(0);
    ASSERT_EQUAL_PTR(0, call NicA.rxMetadata());
  }

  event void Boot.booted () {
    printf("There are %d interfaces with %d addresses each\r\n",
           call WhiteboxNetworkInterfaces.numNics(),
           call WhiteboxNetworkInterfaces.addressesPerNic());
    testNicId();
    testAddressInitialization();
    initializeAddresses();
    testLinkAddress();
    testBindRelease();
    testJoinLeave();
    testAcceptDeliveryTo();
    testInterfaceIdentifier();
    testInterfaceState();
    testRxMetadata();
    ALL_TESTS_PASSED();
  }
}
