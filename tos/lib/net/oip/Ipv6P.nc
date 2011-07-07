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

#include <net/ipv6.h>
#include <arpa/inet.h>
#include <net/skbuff.h>
#include <net/checksum.h>
#include <netinet/icmp6.h>
#include <net/socket.h>

module Ipv6P {
  provides {
    interface Init;
    interface AddressFamily;
    interface IpEntry;
    interface SocketLevelOptions as SloIpv6;
  }
  uses {
    interface AddressFamilies;
    interface NetworkInterface[ oip_network_id_t net_id ];
    interface Ipv6Header[ uint8_t protocol ];
    interface Icmp6;
    interface IpRouting;
  }
} implementation {

  typedef struct ipv6_opts_t {
    uint8_t multicast_hops;
    uint8_t unicast_hops;
    uint8_t multicast_ifindex;
    uint8_t num_groups;
    struct in6_addr groups[OIP_GROUPS_PER_SOCKET_MAX];
  } ipv6_opts_t;

  ipv6_opts_t options_[OIP_SOCKETS_MAX];

  const struct in6_addr in6addr_any @C() /* = IN6ADDR_ANY_INIT */;
  const struct in6_addr in6addr_loopback @C() = IN6ADDR_LOOPBACK_INIT;

  command error_t Init.init ()
  {
    int i;
    for (i = 0; i < OIP_SOCKETS_MAX; ++i) {
      ipv6_opts_t* op = options_ + i;
      op->multicast_hops = op->unicast_hops = 64;
    }
    return SUCCESS;
  }

  command error_t SloIpv6.getsockopt (uint8_t socket_id,
                                      int option_name,
                                      void* value,
                                      socklen_t* option_len)
  {
    error_t rv;
    ipv6_opts_t* op;
    
    if (socket_id >= OIP_SOCKETS_MAX) {
      return EINVAL;
    }
    op = options_ + socket_id;
    if (sizeof(int) > *option_len) {
      return EINVAL;
    }
    *option_len = sizeof(int);
    rv = EINVAL;
    switch (option_name) {
      case IPV6_MULTICAST_IF:
        *(int*)value = op->multicast_ifindex;
        rv = SUCCESS;
        break;
      case IPV6_MULTICAST_HOPS:
        *(int*)value = op->multicast_hops;
        rv = SUCCESS;
        break;
      case IPV6_UNICAST_HOPS:
        *(int*)value = op->unicast_hops;
        rv = SUCCESS;
        break;
      default:
        break;
    }
    return rv;
  }

  command error_t SloIpv6.setsockopt (uint8_t socket_id,
                                      int option_name,
                                      const void* value,
                                      socklen_t option_len)
  {
    error_t rv;
    ipv6_opts_t* op;
    int iv;
    
    if (socket_id >= OIP_SOCKETS_MAX) {
      return EINVAL;
    }
    op = options_ + socket_id;
    if (sizeof(int) > option_len) {
      return EINVAL;
    }
    iv = *(int*)value;
    rv = EINVAL;
    switch (option_name) {
      case IPV6_MULTICAST_IF:
        /* Allow setting to 0 to indicate no associated IF */
        if ((0 <= iv) && (iv <= OIP_NETWORK_INTERFACE_MAX)) {
          op->multicast_ifindex = iv;
          rv = SUCCESS;
        }
        break;
      case IPV6_MULTICAST_HOPS:
        if ((0 < iv) && (iv <= 255)) {
          op->multicast_hops = iv;
          rv = SUCCESS;
        }
        break;
      case IPV6_UNICAST_HOPS:
        if ((0 < iv) && (iv <= 255)) {
          op->unicast_hops = iv;
          rv = SUCCESS;
        }
        break;
      case IPV6_JOIN_GROUP:
      case IPV6_LEAVE_GROUP: {
        const struct sockaddr* sap = (const struct sockaddr*)value;
        const struct sockaddr_in6* s6p = (const struct sockaddr_in6*)value;
        uint8_t gi;
        
        if (option_len < sizeof(*s6p)) {
          break;
        }
        /* @TODO Handle non-INET6 address families in the INET6 domain */
        if (AF_INET6 != s6p->sin6_family) {
          break;
        }
        if (! IN6_IS_ADDR_MULTICAST(&s6p->sin6_addr)) {
          return EINVAL;
        }
        if (s6p->sin6_scope_id != call NetworkInterface.id[s6p->sin6_scope_id]()) {
          return EINVAL;
        }
        if (IPV6_JOIN_GROUP == option_name) {
          /* Find a slot to store the group address in this socket */
          gi = op->num_groups;
          if (gi >= (sizeof(op->groups)/sizeof(*op->groups))) {
            rv = ENOMEM;
          } else {
            /* Only try to join if we are able to store fact-of join
             * in this socket. */
            rv = call NetworkInterface.joinGroup[s6p->sin6_scope_id](sap);
          }
          if (SUCCESS == rv) {
            memcpy(op->groups + gi, &s6p->sin6_addr, sizeof(s6p->sin6_addr));
            ++op->num_groups;
          }
        } else {
          /* See if we are already subscribed */
          for (gi = 0; gi < op->num_groups; ++gi) {
            if (0 == memcmp(op->groups + gi, &s6p->sin6_addr, sizeof(s6p->sin6_addr))) {
              break;
            }
          }
          if (gi < op->num_groups) {
            rv = call NetworkInterface.leaveGroup[s6p->sin6_scope_id](sap);
            op->num_groups -= 1;
            if (gi < op->num_groups) {
              memmove(op->groups + gi, op->groups + gi + 1, (op->num_groups - gi) * sizeof(*op->groups));
            }
          }
        }
      }
      default:
        break;
    }
    return rv;
  }

  command bool AddressFamily.socketInGroup (const struct sockaddr* addr,
                                            uint8_t socket_id,
                                            oip_network_id_t nic_id1)
  {
    ipv6_opts_t* op;
    const struct sockaddr_in6* s6p;
    const struct sockaddr* const* joined_groups;
    int num_joined_groups;
    bool rv;
    int gi;
    
    if (socket_id >= OIP_SOCKETS_MAX) {
      return FALSE;
    }
    op = options_ + socket_id;
    if (AF_INET6 != addr->sa_family) {
      return FALSE;
    }
    s6p = (const struct sockaddr_in6*)addr;

    rv = FALSE;
    for (gi = 0; (gi < op->num_groups) && (! rv); ++gi) {
      rv = (0 == memcmp(op->groups + gi, &s6p->sin6_addr, sizeof(s6p->sin6_addr)));
    }
    if (! rv) {
      return FALSE;
    }

    num_joined_groups = call NetworkInterface.joinedGroups[nic_id1](&joined_groups);
    for (gi = 0; gi < num_joined_groups; ++gi) {
      if (call AddressFamilies.addressEqual(addr, joined_groups[gi])) {
        return TRUE;
      }
    }
    return FALSE;
    
  }

  command sa_family_t AddressFamily.family () { return AF_INET6; }

  command socklen_t AddressFamily.sockaddrLength () { return sizeof(struct sockaddr_in6); }
  command int AddressFamily.inaddrLength () { return sizeof(((struct sockaddr_in6*)0)->sin6_addr); }
  command const uint8_t* AddressFamily.inaddrPointer (const struct sockaddr* addr)
  {
    return (uint8_t*)&((const struct sockaddr_in6*)addr)->sin6_addr;
  }
  command uint16_t AddressFamily.getPort (const struct sockaddr* addr)
  {
    return ((const struct sockaddr_in6*)addr)->sin6_port;
  }
  command void AddressFamily.setPort (struct sockaddr* addr,
                                      uint16_t port)
  {
    ((struct sockaddr_in6*)addr)->sin6_port = port;
  }
  command oip_network_id_t AddressFamily.getNicId (const struct sockaddr* addr)
  {
    return ((const struct sockaddr_in6*)addr)->sin6_scope_id;
  }
  command void AddressFamily.setNicId (struct sockaddr* addr,
                                       oip_network_id_t nic_id1)
  {
    ((struct sockaddr_in6*)addr)->sin6_scope_id = nic_id1;
  }

  command uint16_t AddressFamily.ipMagicChecksum (const struct sockaddr* saddr,
                                                  const struct sockaddr* daddr,
                                                  uint16_t len,
                                                  uint8_t proto,
                                                  uint16_t csum)
  {
    register const uint16_t* pa;
    register uint8_t groups;

    /* Remember to convert values that are stored as multi-octet
     * sequences in network byte order when computing checksum. */
    uint16_t nproto = htons(proto);
    len = htons(len);

    csum += len;
    csum += (csum < len);

    csum += nproto;
    csum += (csum < nproto);

    // assert AF_INET6 == saddr->sa_family;
    pa = (const uint16_t*)&((const struct sockaddr_in6*)saddr)->sin6_addr.s6_addr;
    groups = 8;
    while (groups--) {
      csum += *pa;
      csum += (csum < *pa++);
    }
    pa = (const uint16_t*)&((const struct sockaddr_in6*)daddr)->sin6_addr.s6_addr;
    groups = 8;
    while (groups--) {
      csum += *pa;
      csum += (csum < *pa++);
    }
    return csum;
  }

  command int AddressFamily.storeIpHeader (const struct sockaddr* saddr,
                                           const struct sockaddr* daddr,
                                           unsigned int len,
                                           unsigned int protocol,
                                           uint8_t* dst)
  {
    struct ipv6hdr* h = (struct ipv6hdr*)dst;
    if (0 != h) {
      memset(h, 0, sizeof(*h));
      h->version = 6;
      h->payload_len = htons(len);
      h->hop_limit = 64; /* TEMPORARY */
      h->nexthdr = protocol;
      memcpy(&h->saddr, ((struct sockaddr_in6*)saddr)->sin6_addr.s6_addr, sizeof(struct in6_addr));
      memcpy(&h->daddr, ((struct sockaddr_in6*)daddr)->sin6_addr.s6_addr, sizeof(struct in6_addr));
    }
    return sizeof(*h);
  }

  command bool AddressFamily.addressEqual (const struct sockaddr* addr1,
                                           const struct sockaddr* addr2)
  {
    const struct sockaddr_in6* a1p = (const struct sockaddr_in6*)addr1;
    const struct sockaddr_in6* a2p = (const struct sockaddr_in6*)addr2;

    if ((! addr1) || (! addr2)) {
      return FALSE;
    }
    if (a1p->sin6_family != a2p->sin6_family) {
      return FALSE;
    }
    return 0 == memcmp(&a1p->sin6_addr, &a2p->sin6_addr, sizeof(a1p->sin6_addr));
  }

  command bool AddressFamily.addressIsWildcard (const struct sockaddr* addr)
  {
    return IN6_IS_ADDR_UNSPECIFIED(&((const struct sockaddr_in6*)addr)->sin6_addr);
  }

  command bool AddressFamily.addressIsMulticast (const struct sockaddr* addr)
  {
    return IN6_IS_ADDR_MULTICAST(&((const struct sockaddr_in6*)addr)->sin6_addr);
  }

  command bool AddressFamily.acceptDeliveryTo (const struct sockaddr* daddr,
                                               oip_network_id_t nic_id1)
  {
    const struct sockaddr_in6* da6p = (const struct sockaddr_in6*)daddr;
    const struct in6_addr* i6p;
    const struct sockaddr* const* bound_addresses;
    int num_bound_addresses = call NetworkInterface.boundAddresses[nic_id1](&bound_addresses);
    int i;
    bool rc = TRUE;
    
    if ((! daddr) || (AF_INET6 != da6p->sin6_family)) {
      return FALSE;
    }

    i6p = &da6p->sin6_addr;
    if (IN6_IS_ADDR_MULTICAST(&da6p->sin6_addr)) {
      const struct sockaddr* const* joined_groups;
      int num_joined_groups = call NetworkInterface.joinedGroups[nic_id1](&joined_groups);

      for (i = 0; i < num_joined_groups; ++i) {
        if (call AddressFamilies.addressEqual(daddr, joined_groups[i])) {
          return TRUE;
        }
      }

      /* Solicited-node multicast group for bound address on interface? */
      if ((ntohs(0xFF02) == da6p->sin6_addr.s6_addr16[0])
          && (0 == da6p->sin6_addr.s6_addr16[1])
          && (0 == da6p->sin6_addr.s6_addr16[2])
          && (0 == da6p->sin6_addr.s6_addr16[3])
          && (0 == da6p->sin6_addr.s6_addr16[4])
          && (ntohs(1) == da6p->sin6_addr.s6_addr16[5])
          && (0xff == da6p->sin6_addr.s6_addr[12])) {

        /* Destination is a solicited-node multicast address.  Octets
         * 13, 14, 15 are the low bits of unicast/anycast addresses.
         * Check for a match with those. */
        for (i = 0; i < num_bound_addresses; ++i) {
          const struct sockaddr_in6* a6p = (const struct sockaddr_in6*)bound_addresses[i];
          if ((! a6p)
              || (AF_INET6 != a6p->sin6_family)
              || IN6_IS_ADDR_MULTICAST(&a6p->sin6_addr)
              || IN6_IS_ADDR_LINKLOCAL(&a6p->sin6_addr)
            ) {
            continue;
          }
          if ((da6p->sin6_addr.s6_addr[13] == a6p->sin6_addr.s6_addr[13])
              && (da6p->sin6_addr.s6_addr16[7] == a6p->sin6_addr.s6_addr16[7])) {
            return TRUE;
          }
        }
      }
      
      /* Only potentials are pre-defined addresses */
      if (1 == i6p->s6_addr[15]) {
        /* All nodes: FF01::1, FF02::1 */
        if ((1 != i6p->s6_addr[1]) && (2 != i6p->s6_addr[1])) {
          return FALSE;
        }
      } else if (2 == i6p->s6_addr[15]) {
        /* All routers: FF01::2, FF02::2, FF05::2 */
        rc = call IpRouting.routeOnInterface(nic_id1);
        if (rc && (1 != i6p->s6_addr[1]) && (2 != i6p->s6_addr[1]) && (5 != i6p->s6_addr[1])) {
          rc = FALSE;
        }
      } else {
        /* Not a recognized address */
        return FALSE;
      }

      /* Finish validation: interior octets must be zero */
      for (i = 2; rc && (i < 15); ++i) {
        if (i6p->s6_addr[i]) {
          return FALSE;
        }
      }
      return rc;
    }

    for (i = 0; i < num_bound_addresses; ++i) {
      if (call AddressFamilies.addressEqual(daddr, bound_addresses[i])) {
        return TRUE;
      }
    }
    return FALSE;
  }

  command bool AddressFamily.addressPrefixMatch (const struct sockaddr* addr,
                                                 const uint8_t* prefix,
                                                 unsigned int prefix_length_bits)
  {
    const uint8_t* ap;
    const struct sockaddr_in6* a6p = (const struct sockaddr_in6*)addr;
    if (! a6p) {
      return FALSE;
    }
    ap = a6p->sin6_addr.s6_addr;
    while (8 <= prefix_length_bits) {
      if (*ap++ != *prefix++) {
        return FALSE;
      }
      prefix_length_bits -= 8;
    }
    if (0 < prefix_length_bits) {
      uint16_t mask = ~((1 << (8 - prefix_length_bits)) - 1);
      if ((mask & *ap) != (mask & *prefix)) {
        return FALSE;
      }
    }
    return TRUE;
  }

  static const uint8_t link_local_prefix[] = { 0xfe, 0x80 };
  enum {
    /** Number of bits in the address prefix for a link-local address */
    LINK_LOCAL_PREFIX_LENGTH_BITS = 10,

    /** Number of octets we allow for the IID portion of the
     * link-local address.  Most IIDs will be 64 bits = 8 octets.
     * Technically, this value should be 14.75, since the lower six
     * bits of the second octet are part of the IID, but to enable
     * that would require bit masking to handle a pretty unusual case.
     * When you need a full 118-bit IID, you can fix it then. */
    LINK_LOCAL_IID_LENGTH_OCTETS = 14,
  };

  event void NetworkInterface.interfaceState[ oip_network_id_t nic_id1 ] (oip_nic_state_t state)
  {
    const struct sockaddr* llp;
    error_t rc;

    llp = call NetworkInterface.locatePrefixBinding[nic_id1](AF_INET6, link_local_prefix, LINK_LOCAL_PREFIX_LENGTH_BITS);
    if (IFF_UP & state) {
      union sockaddr_u {
        struct sockaddr sa;
        struct sockaddr_in6 s6;
      } address;
      const uint8_t* iid;
      int iid_len_bits;
      int iid_len;

      /* If we already have a link-local address, we don't need to do
       * anything. */
      if (llp) {
        return;
      }

      /* Get the interface identifier.  If there isn't one, somebody
       * screwed up: it was supposed to have been made available
       * before we got this event. */
      iid = call NetworkInterface.interfaceIdentifier[nic_id1]();
      if (! iid) {
        return;
      }

      /* How long is the IID, in octets (rounded up)?  If it would
       * intrude into the octets used for the address prefix, don't
       * use it. */
      iid_len_bits = call NetworkInterface.interfaceIdentifierLength_bits[nic_id1]();
      iid_len = (iid_len_bits + 7) / 8;
      if (LINK_LOCAL_IID_LENGTH_OCTETS < iid_len) {
        return;
      }

      memset(address.s6.sin6_addr.s6_addr, 0, sizeof(address.s6.sin6_addr));
      address.s6.sin6_family = AF_INET6;
      address.s6.sin6_addr.s6_addr[0] = 0xfe;
      address.s6.sin6_addr.s6_addr[1] = 0x80;
      memcpy(address.s6.sin6_addr.s6_addr + 16 - iid_len, iid, iid_len);

      rc = call NetworkInterface.bindAddress[nic_id1](&address.sa);
    } else {
      if (llp) {
        rc = call NetworkInterface.releaseAddress[nic_id1](llp);
      }
    }
  }

  /* Return FALSE to indicate an unrecognized header */
  default command bool Ipv6Header.process[ uint8_t protocol ] (struct sk_buff* skb,
                                                               const uint8_t** payloadp,
                                                               const uint8_t** nexthdrpp,
                                                               unsigned int *payload_lenp)
  { return FALSE; }

  default command bool IpRouting.routeOnInterface (oip_network_id_t nic_id1) { return FALSE; }

  command error_t IpEntry.deliver (oip_network_id_t nic_id1,
                                   void * oip_network_data,
                                   const uint8_t* data,
                                   unsigned int len)
  {
    struct sk_buff skb;
    const struct ipv6hdr* h = (const struct ipv6hdr*)data;
    const uint8_t* payload = data + sizeof(*h);
    uint16_t payload_len = ntohs(h->payload_len);
    const uint8_t* nexthdrp = &h->nexthdr;
    union {
        struct sockaddr sa;
        struct sockaddr_in6 s6;
    } srcu,
      dstu;
    bool recognize_nexthdr = TRUE;

#if 0
    printf("IPv6 via %d: %u nxt %u la %s ", nic_id1, payload_len, *nexthdrp, getnameinfo(call NetworkInterface.getLinkAddress[nic_id1]()));
    printf("src %s ", inet_ntop(AF_INET6, &h->saddr));
    printf("dst %s\r\n", inet_ntop(AF_INET6, &h->daddr));
#endif
#if 0
    {
      uint8_t* dp = payload;
      uint8_t* dpe = dp + payload_len;
      printf("iprx ");
      while (dp < dpe) {
        printf(" %02x", *dp++);
      }
      printf("\r\n");
    }
#endif
    
    skb.nic_id = nic_id1;
    skb.nic_data = oip_network_data;
    skb.src = &srcu.sa;
    srcu.s6.sin6_family = AF_INET6;
    srcu.s6.sin6_addr = h->saddr;
    srcu.s6.sin6_scope_id = nic_id1;
    skb.dst = &dstu.sa;
    dstu.s6.sin6_family = AF_INET6;
    dstu.s6.sin6_addr = h->daddr;
    dstu.s6.sin6_scope_id = nic_id1;

    skb.proto = *nexthdrp;
    if (NEXTHDR_HOP == *nexthdrp) {
      /* Process hop-by-hop options header */
      recognize_nexthdr = call Ipv6Header.process[*nexthdrp](&skb, &payload, &nexthdrp, &payload_len);
    }
    if (call NetworkInterface.acceptDeliveryTo[skb.nic_id](skb.dst)) {
      while (recognize_nexthdr && nexthdrp) {
        skb.proto = *nexthdrp;
        if (NEXTHDR_HOP == *nexthdrp) {
          recognize_nexthdr = FALSE;
        } else {
          recognize_nexthdr = call Ipv6Header.process[*nexthdrp](&skb, &payload, &nexthdrp, &payload_len);
        }
      }
    }
    if (! recognize_nexthdr) {
      // Send ICMP Parameter Problem code 1
      call Icmp6.generate(ICMP6_PARAM_PROB, ICMP6_PARAM_PROB_NEXTHEADER, (nexthdrp - data), skb.dst, skb.src, data, len);
    }
    if (call IpRouting.routeOnInterface(nic_id1)) {
      /* Route the packet */
    }

    return SUCCESS;
  }
  
}
