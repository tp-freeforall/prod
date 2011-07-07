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

/** POSIX-conformant <netinet/in.h> file.
 *
 * This defines the minimum required by POSIX consistent with OIP capabilities.
 *
 * @note POSIX mandates that addresses and ports be stored in network
 * byte order.  We intentionally do not use nesC's constructs for this
 * (nx_uint*_t), because POSIX programmers are aware of the difference
 * between host and byte order, and will invoke the appropriate
 * conversion routines when necessary.  Use of these routines is much
 * faster and space efficient than the overhead imposed by using
 * nx_uint*_t. */
   
#ifndef OSIAN_OIP_NETINET_IN_H_
#define OSIAN_OIP_NETINET_IN_H_

#include <stdint.h>
#include <sys/socket.h>

/** Symbolic constants for use as level argument of *sockopt().  By
 * convention, the values for these are the corresponding IANA
 * assigned protocol number.
 */
enum {
  IPPROTO_IP = 0, /* NB: Not an assigned protocol number */
  IPPROTO_IPV6 = 41,
  IPPROTO_ICMP = 1,
  IPPROTO_RAW = 255, /* NB: Not an assigned protocol number */
  IPPROTO_TCP = 6,
  IPPROTO_UDP = 17,
};
/** Symbolic constants for other IANA assigned protocols that are not
 * used as level arguments to sockopt, but are convenient to have in
 * parallel to the previous constants. */
enum {
  IPPROTO_HOPOPT = 0,
  IPPROTO_ICMPV6 = 58,
  IPPROTO_RESERVED = 255,
};

#if 0
typedef uint16_t in_port_t;
typedef uint32_t in_addr_t;
#endif

struct in_addr {
  in_addr_t s_addr;
};

struct sockaddr_in {
  sa_family_t sin_family;
  in_port_t sin_port;
  struct in_addr sin_addr;
};

struct in6_addr {
  union {
    uint8_t s6_un_addr8[16];
    uint16_t s6_un_addr16[8];
    uint32_t s6_un_addr32[4];
  } s6_un;
#define s6_addr s6_un.s6_un_addr8
#define s6_addr16 s6_un.s6_un_addr16
#define s6_addr32 s6_un.s6_un_addr32
};

struct sockaddr_in6 {
  sa_family_t sin6_family;
  in_port_t sin6_port;
  uint32_t sin6_flowinfo;
  /** For link-local addresses, sin6_scope_id is set to 1 plus the id
   * of the NetworkInterface to which the address is (or should be)
   * bound. */
  uint32_t sin6_scope_id;
  struct in6_addr sin6_addr;
};

#define IN6ADDR_ANY_INIT { { { 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 } } }
extern const struct in6_addr in6addr_any;
#define IN6ADDR_LOOPBACK_INIT { { { 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1 } } }
extern const struct in6_addr in6addr_loopback;

struct ipv6_mreq {
  struct in6_addr ipv6mr_multiaddr;
  unsigned ipv6mr_interface;
};

#define IN6_IS_ADDR_UNSPECIFIED(_a) ({ \
  int rv = 1; \
  int wi = 0; \
  while (rv && (wi < 8)) { \
    rv = (0 == (_a)->s6_addr16[wi++]); \
  } \
  rv; \
})
  
#define IN6_IS_ADDR_LOOPBACK(_a) ({ \
  int rv = 1; \
  int wi = 0; \
  while (rv && (wi < 7)) { \
    rv = (0 == (_a)->s6_addr16[wi++]); \
  } \
  rv && (0 == (_a)->s6_addr[14]) && (1 == (_a)->s6_addr[15]); \
})

#define IN6_IS_ADDR_MULTICAST(_a) (0xff == (_a)->s6_addr[0])
  
#define IN6_IS_ADDR_LINKLOCAL(_a) (0xfe80 == (0xffc0 & ntohs((_a)->s6_addr16[0])))
#define IN6_IS_ADDR_SITELOCAL(_a) (0xfec0 == (0xffc0 & ntohs((_a)->s6_addr16[0])))

#define IN6_IS_ADDR_V4MAPPED(_a) ({ \
  int rv = 1; \
  int wi = 0; \
  while (rv && (wi < 5)) { \
    rv = (0 == (_a)->s6_addr16[wi++]); \
  } \
  rv && (0xffff == (_a)->s6_addr16[5]) && (1 < ntohl(*(uint32_t*)(12 + (_a)->s6_addr))); \
})

#define IN6_IS_ADDR_V4COMPAT(_a) ({ \
  int rv = 1; \
  int wi = 0; \
  while (rv && (wi < 6)) { \
    rv = (0 == (_a)->s6_addr16[wi++]); \
  } \
  rv && (1 < ntohl(*(uint32_t*)(12 + (_a)->s6_addr))); \
})

/* Value used is the scop field from the multicast address (RFC4291
 * section 2.7) */
#define IN6_IS_ADDR_MC_NODELOCAL(_a) (IN6_IS_ADDR_MULTICAST(_a) && (0x01 == (0x0F & (_a)->s6_addr[1])))
#define IN6_IS_ADDR_MC_LINKLOCAL(_a) (IN6_IS_ADDR_MULTICAST(_a) && (0x02 == (0x0F & (_a)->s6_addr[1])))
#define IN6_IS_ADDR_MC_SITELOCAL(_a) (IN6_IS_ADDR_MULTICAST(_a) && (0x05 == (0x0F & (_a)->s6_addr[1])))
#define IN6_IS_ADDR_MC_ORGLOCAL(_a)  (IN6_IS_ADDR_MULTICAST(_a) && (0x08 == (0x0F & (_a)->s6_addr[1])))
#define IN6_IS_ADDR_MC_GLOBAL(_a)    (IN6_IS_ADDR_MULTICAST(_a) && (0x0e == (0x0F & (_a)->s6_addr[1])))

/* IPPROTO_IPV6 level socket options */
enum {
  /** Join the group identified by the provided address.
   *
   * The value is a pointer to a sockaddr_AF structure for an address
   * family that supports IPv6 communications.  The value of the
   * address (not its pointer) is used to allocate a new address
   * structure, which is then bound to the network interface
   * identified in the address scope field.
   *
   * This option can only be set. */
  IPV6_JOIN_GROUP = 1,

  /** Leave the group identified by the provided address.
   *
   * The value is a pointer to a sockaddr_AF structure for an address
   * family that supports IPv6 communications.  The value of the
   * address (not its pointer) is used to locate a matching address
   * record created by a previous IPV6_JOIN_GROUP action; that address
   * is dissociated for the NIC identified by the address scope field
   * and is returned to the address pool.
   *
   * This option can only be set. */
  IPV6_LEAVE_GROUP,

  /** Set and retrieve the value of the hop_limit in the IPv6 header
   * for outgoing multicast packets. */
  IPV6_MULTICAST_HOPS,

  /** Set and retrieve the value of the hop_limit in the IPv6 header
   * for outgoing non-multicast packets. */
  IPV6_UNICAST_HOPS,

  /** Set and retrieve the identifier for the network interface to be
   * used for outgoing multicast packets.  A value of zero indicates
   * no associated interface (transmitted multicast packets will not
   * be sent). */
  IPV6_MULTICAST_IF,

  IPV6_V6ONLY,
  IPV6_MULTICAST_LOOP,
};

#endif /* OSIAN_OIP_NETINET_IN_H_ */
