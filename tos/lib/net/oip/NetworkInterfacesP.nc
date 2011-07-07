/* Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

#include <net/if.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/in.h>

module NetworkInterfacesP {
  provides {
    interface NetworkInterface[ oip_network_id_t nic_id1 ];
#ifdef TEST_NETWORK_INTERFACES
    interface WhiteboxNetworkInterfaces;
#endif /* TEST_NETWORK_INTERFACES */
  }
  uses {
    interface AddressFamilies;
    interface FragmentPool;
    interface NetworkLinkInterface[ oip_network_id_t nic_id1 ];
    interface NetworkInterfaceIdentifier[ oip_network_id_t nic_id1 ];
  }
} implementation {
  enum {
    /** Maximum number of addresses assigned to any NIC. */
    AddressesPerNic = OIP_ADDRESSES_PER_NIC,
    /** Maximum number of groups that any NIC can join. */
    GroupsPerNic = OIP_GROUPS_PER_NIC,
  };

  typedef struct nic_metadata_t {
    struct sockaddr* linkAddress;
    union {
      struct sockaddr* nc[AddressesPerNic];
      const struct sockaddr* c[AddressesPerNic];
    } addresses;
    union {
      struct sockaddr* nc[GroupsPerNic];
      const struct sockaddr* c[GroupsPerNic];
    } groups;
    const void* rxMetadata;
    oip_nic_state_t state;
  } nic_metadata_t;

  nic_metadata_t nic_metadata[OIP_NETWORK_INTERFACE_MAX];

  int count_ (const struct sockaddr* const* addrp,
              uint8_t limit)
  {
    int num_addresses = 0;

    while ((num_addresses < limit) && (0 != addrp[num_addresses])) {
      ++num_addresses;
    }
    return num_addresses;
  }

#ifdef TEST_NETWORK_INTERFACES
  command int WhiteboxNetworkInterfaces.numNics () { return OIP_NETWORK_INTERFACE_MAX; }
  command int WhiteboxNetworkInterfaces.addressesPerNic () { return AddressesPerNic; }
  command int WhiteboxNetworkInterfaces.groupsPerNic () { return GroupsPerNic; }
  command const struct sockaddr* WhiteboxNetworkInterfaces.linkAddress (oip_network_id_t nic_id1) { return nic_metadata[nic_id1-1].linkAddress; }
  command const struct sockaddr* const* WhiteboxNetworkInterfaces.addresses (oip_network_id_t nic_id1) { return nic_metadata[nic_id1-1].addresses.c; }
  command const struct sockaddr* const* WhiteboxNetworkInterfaces.groups (oip_network_id_t nic_id1) { return nic_metadata[nic_id1-1].groups.c; }
  command oip_nic_state_t WhiteboxNetworkInterfaces.NetworkInterface_getInterfaceState (oip_network_id_t nic_id1) { return call NetworkInterface.getInterfaceState[nic_id1](); }
#endif /* TEST_NETWORK_INTERFACES */

  command oip_network_id_t NetworkInterface.id[ oip_network_id_t nic_id1 ] () { return (1 <= nic_id1) && (nic_id1 <= OIP_NETWORK_INTERFACE_MAX) ? nic_id1 : -1; }

  struct sockaddr*
  duplicateSockaddr (const struct sockaddr* addr)
  {
    uint8_t* start;
    uint8_t* end;
    error_t rc;
    socklen_t sa_len;

    sa_len = call AddressFamilies.sockaddrLength(addr->sa_family);
    if (0 >= sa_len) {
      return 0;
    }
    rc = call FragmentPool.request(&start, &end, sa_len);
    if (SUCCESS != rc) {
      return 0;
    }
    rc = call FragmentPool.freeze(start, start + sa_len);
    if (SUCCESS != rc) {
      call FragmentPool.release(start);
      return 0;
    }
    memcpy(start, addr, sa_len);
    return (struct sockaddr*)start;
  }

  async event void FragmentPool.available (unsigned int length) { }

  error_t releaseSockaddr (const struct sockaddr* addr)
  {
    return call FragmentPool.release((const uint8_t*)addr);
  }

  command error_t NetworkInterface.setLinkAddress[ oip_network_id_t nic_id1 ] (const struct sockaddr* addr)
  {
    nic_metadata_t* mp = nic_metadata + nic_id1 - 1;
    error_t rv = SUCCESS;
    
    if (addr && mp->linkAddress) {
      return EALREADY;
    }
    if (addr) {
      mp->linkAddress = duplicateSockaddr(addr);
      if (! mp->linkAddress) {
        return ENOMEM;
      }
      call AddressFamilies.setNicId(mp->linkAddress, nic_id1);
    } else if (mp->linkAddress) {
      rv = releaseSockaddr(mp->linkAddress);
      mp->linkAddress = 0;
    }
    return rv;
  }

  command const struct sockaddr* NetworkInterface.getLinkAddress[ oip_network_id_t nic_id1 ] ()
  {
    return nic_metadata[nic_id1 - 1].linkAddress;
  }

  struct sockaddr* bindAddress_ (const struct sockaddr* addr,
                                 struct sockaddr** addresses,
                                 uint8_t limit)
  {
    struct sockaddr** sapp = addresses;
    struct sockaddr** sappe = sapp + limit;

    while ((sapp < sappe) && (*sapp)) {
      ++sapp;
    }
    if (sapp >= sappe) {
      return 0;
    }
    *sapp = duplicateSockaddr(addr);
    return *sapp;
  }

  struct sockaddr** findBoundAddress_ (const struct sockaddr* addr,
                                       struct sockaddr** addresses,
                                       uint8_t limit)
  {
    struct sockaddr** sapp = addresses;
    struct sockaddr** sappe = addresses + limit;

    while ((sapp < sappe) && (*sapp)) {
      if (call AddressFamilies.addressEqual(addr, *sapp)) {
        return sapp;
      }
      ++sapp;
    }
    return 0;
  }

  error_t releaseAddress_ (const struct sockaddr* addr,
                           struct sockaddr** addresses,
                           uint8_t limit)
  {
    struct sockaddr** sapp;
    struct sockaddr** sappe = addresses + limit;
    error_t rv;

    sapp = findBoundAddress_(addr, addresses, limit);
    if (! sapp) {
      return EINVAL;
    }
    rv = releaseSockaddr(*sapp);
    while (++sapp < sappe) {
      sapp[-1] = sapp[0];
    }
    sapp[-1] = 0;
    return rv;
  }

  command error_t NetworkInterface.bindAddress[ oip_network_id_t nic_id1 ] (const struct sockaddr* addr)
  {
    nic_metadata_t* mp = nic_metadata + nic_id1 - 1;
    struct sockaddr* sap;

    sap = bindAddress_(addr, mp->addresses.nc, sizeof(mp->addresses.nc)/sizeof(*mp->addresses.nc));
    if (! sap) {
      return ENOMEM;
    }
    call AddressFamilies.setNicId(sap, nic_id1);
    return SUCCESS;
  }

  command error_t NetworkInterface.joinGroup[ oip_network_id_t nic_id1 ] (const struct sockaddr* addr)
  {
    nic_metadata_t* mp = nic_metadata + nic_id1 - 1;
    struct sockaddr* sap;

    sap = bindAddress_(addr, mp->groups.nc, sizeof(mp->groups.nc)/sizeof(*mp->groups.nc));
    return sap ? SUCCESS : ENOMEM;
  }

  command error_t NetworkInterface.releaseAddress[ oip_network_id_t nic_id1 ] (const struct sockaddr* addr)
  {
    nic_metadata_t* mp = nic_metadata + nic_id1 - 1;
    return releaseAddress_(addr, mp->addresses.nc, sizeof(mp->addresses.nc)/sizeof(*mp->addresses.nc));
  }

  command error_t NetworkInterface.leaveGroup[ oip_network_id_t nic_id1 ] (const struct sockaddr* addr)
  {
    nic_metadata_t* mp = nic_metadata + nic_id1 - 1;
    return releaseAddress_(addr, mp->groups.nc, sizeof(mp->groups.nc)/sizeof(*mp->groups.nc));
  }

  command int NetworkInterface.acceptDeliveryTo[ oip_network_id_t nic_id1 ] (const struct sockaddr* addr)
  {
    if (IFF_PROMISC & nic_metadata[nic_id1-1].state) {
      return 1;
    }
    return call AddressFamilies.acceptDeliveryTo(addr, nic_id1);
  }

  command const struct sockaddr* NetworkInterface.locatePrefixBinding[ oip_network_id_t nic_id1 ] (sa_family_t address_family,
                                                                                                   const uint8_t* prefix,
                                                                                                   unsigned int prefix_length_bits)
  {
    const nic_metadata_t* mp = nic_metadata + nic_id1 - 1;
    const struct sockaddr* const* sapp = mp->addresses.c;
    const int num_addresses = sizeof(mp->addresses.c) / sizeof(*mp->addresses.c);
    int i;

    for (i = 0; (i < num_addresses) && (*sapp); ++i, ++sapp) {
      if ((address_family == (*sapp)->sa_family)
          && (call AddressFamilies.addressPrefixMatch(*sapp, prefix, prefix_length_bits))) {
        return *sapp;
      }
    }
    return 0;
  }

  command int NetworkInterface.boundAddresses[ oip_network_id_t nic_id1 ] (const struct sockaddr* const** addrsp)
  {
    const nic_metadata_t* mp = nic_metadata + nic_id1 - 1;

    if (! addrsp) {
      return -1;
    }
    *addrsp = mp->addresses.c;
    return count_(mp->addresses.c, sizeof(mp->addresses.c)/sizeof(*mp->addresses.c));
  }

  command int NetworkInterface.joinedGroups[ oip_network_id_t nic_id1 ] (const struct sockaddr* const** addrsp)
  {
    const nic_metadata_t* mp = nic_metadata + nic_id1 - 1;

    if (! addrsp) {
      return -1;
    }
    *addrsp = mp->groups.c;
    return count_(mp->groups.c, sizeof(mp->groups.c)/sizeof(*mp->groups.c));
  }


  default command error_t NetworkLinkInterface.transmit[ oip_network_id_t nic_id1 ] (const void* message,
                                                                                     unsigned int len) { return FAIL; }

  command error_t NetworkInterface.transmit[ oip_network_id_t nic_id1 ] (const void* message,
                                                                        unsigned int len)
  {
    return call NetworkLinkInterface.transmit[nic_id1](message, len);
  }

  default command int NetworkLinkInterface.storeLinkHeader[ oip_network_id_t nic_id1 ] (const struct sockaddr* saddr,
                                                                                        const struct sockaddr* daddr,
                                                                                        unsigned int len,
                                                                                           uint8_t* dst) { return -1; }

  command int NetworkInterface.storeLinkHeader[ oip_network_id_t nic_id1 ] (const struct sockaddr* saddr,
                                                                           const struct sockaddr* daddr,
                                                                           unsigned int len,
                                                                           uint8_t* dst)
  {
    return call NetworkLinkInterface.storeLinkHeader[nic_id1](saddr, daddr, len, dst);
  }

  default command const uint8_t* NetworkInterfaceIdentifier.interfaceIdentifier[ oip_network_id_t nic_id1 ] () { return 0; }
  command const uint8_t* NetworkInterface.interfaceIdentifier[ oip_network_id_t nic_id1 ] () { return call NetworkInterfaceIdentifier.interfaceIdentifier[nic_id1](); }

  default command uint8_t NetworkInterfaceIdentifier.interfaceIdentifierLength_bits[ oip_network_id_t nic_id1 ] () { return 0; }
  command uint8_t NetworkInterface.interfaceIdentifierLength_bits[ oip_network_id_t nic_id1 ] () { return call NetworkInterfaceIdentifier.interfaceIdentifierLength_bits[nic_id1](); }
  
  event void NetworkLinkInterface.provideRxMetadata[ oip_network_id_t nic_id1 ] (const void* rx_metadata)
  {
    nic_metadata[nic_id1-1].rxMetadata = rx_metadata;
  }

  command const void* NetworkInterface.rxMetadata[ oip_network_id_t nic_id1 ] () { return nic_metadata[nic_id1-1].rxMetadata; }

  default event void NetworkInterface.interfaceState[ oip_network_id_t nic_id1 ] (oip_nic_state_t state) { }

  command oip_nic_state_t NetworkInterface.getInterfaceState[ oip_network_id_t nic_id1 ] ()
  {
    return ((0 < nic_id1) && (nic_id1 <= OIP_NETWORK_INTERFACE_MAX)) ? nic_metadata[nic_id1-1].state : IFF_INVALID;
  }
  command void NetworkInterface.setInterfaceState[ oip_network_id_t nic_id1 ] (oip_nic_state_t state)
  {
    nic_metadata[nic_id1-1].state = state;
    signal NetworkInterface.interfaceState[nic_id1](state);
  }

}
