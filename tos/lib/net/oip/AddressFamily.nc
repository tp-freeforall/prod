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

#include <sys/socket.h>
#include <net/if.h>

/** Common operations on IP network addresses belonging to a
 * particular family.
 *
 * An address family determines how an IP address is represented both
 * within the application and on the wire.  These families are in
 * one-to-one association with the AF_* constants defined in
 * <sys/socket.h>.
 *
 * @note Although the AF_* constants that identify address families
 * are also used to specify the domain of a socket, in OSIAN IP the
 * two concepts are not identical.  In particular, the AF_INET6 domain
 * refers to IPv6, while the AF_INET6 address family specifically
 * refers to the representation of IPv6 addresses as in RFC 2460.
 * Other address families such as (TBR) AF_6LOWPAN also traffic in
 * IPv6 packets, but do so with a different network-layer header and
 * encoding of the IPv6 addresses.
 *
 * @warning If you use the structures (like sockaddr_in6) associated
 * with an address family, make sure your application links in the
 * corresponding address family component (like AfInet6C).  If the
 * component is not available does not, some support routine (like
 * getnameinfo) will end up resolving to the default implementation
 * for address family commands (like inaddrPointer), resulting in
 * bizarre behavior.  You'll probably only run into this problem in
 * test applications, but it'll happen, just you wait.
 * 
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface AddressFamily {
  /** Return the address family value supported by this interface.
   *
   * This is primarily used in parameterized interfaces to verify that
   * a particular family is supported.  The return value should be 0
   * for default implementations.
   */
  command sa_family_t family ();

  /** Return the length of the sockaddr_AF structure used to store
   * addresses in this family. */
  command socklen_t sockaddrLength ();

  /** Return a pointer to the underlying IP-level address.
   *
   * Recall that sockaddr structures incorporate INET ports, a family
   * tag, and other information in addition to an IP address.  This
   * command returns the pointer to the underlying address.  Its
   * primary purpose is to obtain, from a sockaddr structure, the
   * value that is to be passed to something like inet_ntop or to
   * serve as the source for a copy into an IP saddr/daddr header
   * field.
   *
   * @param addr The genericized pointer to a sockaddr_AF structure.
   *
   * @return a pointer to the IP-level address within the structure
   * pointed to by addr; or a null pointer if addr does not belong to
   * this family.
   */
  command const uint8_t* inaddrPointer (const struct sockaddr* addr);

  /** Return the length, in octets, of the underlying IP-level address
   * structure. */
  command int inaddrLength ();

  /** Get the port field of the corresponding address, if supported.
   *
   * @param addr the socket address from which the port field should
   * be extracted.
   *
   * @return the value of the port field, or 0 if not supported */
  command uint16_t getPort (const struct sockaddr* addr);

  /** Set the port field of the corresponding address, if supported.
   *
   * @param addr the socket address from which the port field should
   * be extracted.
   *
   * @param port the Internet port to be stored
   */
  command void setPort (struct sockaddr* addr,
                        uint16_t port);

  /** Get the nic id associated with the address.
   *
   * @param addr the address
   *
   * @return The network ID associated with the address, or 0 if
   * none. */
  command oip_network_id_t getNicId (const struct sockaddr* addr);

  /** Set the nic id associated with the address.
   *
   * @param addr the address
   *
   * @param nic_id1 The network interface identifier for an associated
   * NIC, or 0 if the address is not associated with a specific
   * interface.
   */
  command void setNicId (struct sockaddr* addr,
                         oip_network_id_t nic_id1);

  /** Calculate the checksum for an IP header comprising the given
   * information.
   *
   * @param saddr the source address, expected to be in this family
   *
   * @param daddr the destination address, expected to be in this family
   *
   * @param len the payload length, in host byte order
   *
   * @param proto the IP protocol for the header
   *
   * @param csum a partial checksum from other portions of the packet.
   * Pass zero if no other checksum data is currently available.
   *
   * @return a folded IP checksum for the family-specific
   * pseudo-header.
   */
  command uint16_t ipMagicChecksum (const struct sockaddr* saddr,
                                    const struct sockaddr* daddr,
                                    uint16_t len,
                                    uint8_t proto,
                                    uint16_t csum);

  /** Store the family-specific representation of a standard IP header.
   *
   * @TODO Though some attempt is made to be generic, this is expected
   * to be an IPv6 header, and the parameters reflect that use.  There
   * is currently no support for setting traffic class or flow label.
   *
   * @param saddr the source address, expected to be in this family
   *
   * @param daddr the destination address, expected to be in this family
   *
   * @param len the payload length, in host byte order
   *
   * @param proto the IP protocol for the header
   *
   * @param dst a partial checksum from other portions of the packet.
   * Pass zero if no other checksum data is currently available.
   *
   * @return The number of octets used for the IP header.  If dst is
   * null, it is permitted to return a pre-calculated upper bound if
   * the actual size of the header depends on compression of the
   * arguments.  The return value should be -1 in a default
   * parameterized implementation, and zero if the family does not
   * support a form of Internet Protocol.
   */
  command int storeIpHeader (const struct sockaddr* saddr,
                             const struct sockaddr* daddr,
                             unsigned int len,
                             unsigned int protocol,
                             uint8_t* dst);

  /** Return TRUE iff the two addresses are equivalent.
   *
   * Both addresses must belong to this family, and be non-null.  This
   * is tested internally; if not satisfied, returns FALSE.
   *
   * Equivalence is tested at the level of an in_addr: ports are
   * ignored, as is ancillary information like scope.  The equivalence
   * is by value, not pointer.
   *
   * @return TRUE iff the two addresses are equal in the sense defined
   * above.
   */
  command bool addressEqual (const struct sockaddr* addr1,
                             const struct sockaddr* addr2);

  /** Return TRUE iff the address matches the family's representation
   * of the wildcard address.
   * @param addr the address
   * @return TRUE iff the IP address is the family variant of INADDR_ANY
   */
  command bool addressIsWildcard (const struct sockaddr* addr);
  
  /** Check for multicast addresses
   * @param addr the address
   * @return TRUE iff the IP address is a multicast address
   */
  command bool addressIsMulticast (const struct sockaddr* addr);

  /** Determine whether a particular socket has joined the given group.
   *
   * This is used upon packet reception to determine whether an
   * incoming packet should be delivered to a specific non-raw socket.
   * The addr parameter is used only for its inaddr portion.  Group
   * subscriptions on the specific interface are checked relative to
   * the nic_id1 parameter.
   *
   * @param addr A multicast group in this family.  Only the inaddr
   * portion of the socket address is relevant; in particular,
   * scope_id is ignored.
   *
   * @param socket_id The socket id (descriptor) that is to be checked.
   *
   * @param nic_id1 The network interface on which the packet was
   * received.
   *
   * @return TRUE iff the given socket has subscribed to the given
   * address (in this family) on the given interface.
   */
  command bool socketInGroup (const struct sockaddr* addr,
                              uint8_t socket_id,
                              oip_network_id_t nic_id1);

  /** Determine whether addr should be delivered to any of the listed
   * addresses.
   *
   * This routine implements the NetworkInterface acceptDeliveryTo
   * facility.  In some families, like AF_INET6, daddr may specify a
   * generic address which requires costly processing that can be done
   * once rather than for each comparisand.
   *
   * @param daddr The destination address of some packet
   *
   * @param nic_id1 The interface on which the packet was received
   *
   * @return TRUE iff packets sent to daddr should be accepted on
   * interface nic_id1
   */
  command bool acceptDeliveryTo (const struct sockaddr* daddr,
                                oip_network_id_t nic_id1);

  /** Determine whether the prefix matches the given address.
   *
   * @param addr The candidate address.  If null, this command returns FALSE.
   *
   * @param prefix The bit sequence against which the address is to be
   * compared.
   *
   * @param prefix_length_bits The number of initial bits to which the
   * prefix must match the address for success
   *
   * @return TRUE iff the family-specific address representation
   * matches the given prefix in the first prefix_length_bits bits
   */
  command bool addressPrefixMatch (const struct sockaddr* addr,
                                   const uint8_t* prefix,
                                   unsigned int prefix_length_bits);
}
