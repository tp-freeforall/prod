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

/** A genericized version of AddressFamily that makes the common
 * capabilities available without requiring a specific AddressFamily
 * interface implementation nor supporting a parameterized
 * AddressFamily interface with all the default implementations that
 * requires.
 *
 * Not all commands are supported, because so far they haven't been
 * needed outside of AddressFamiliesP, where they're all available.
 *
 * See the AddressFamily interface for the documentation and semantics
 * of each command. */
interface AddressFamilies {
  /** Delegate to AddressFamily.sockaddrLength */
  command socklen_t sockaddrLength (sa_family_t family);

  /** Delegate to AddressFamily.getPort */
  command uint16_t getPort (const struct sockaddr* addr);

  /** Delegate to AddressFamily.setPort */
  command void setPort (struct sockaddr* addr, uint16_t port);

  /** Delegate to AddressFamily.getNicId */
  command oip_network_id_t getNicId (const struct sockaddr* addr);

  /** Delegate to AddressFamily.setNicId */
  command void setNicId (struct sockaddr* addr,
                         oip_network_id_t nic_id1);

  /** Delegate to AddressFamily.inaddrPointer */
  command const uint8_t* inaddrPointer (const struct sockaddr* addr);

  /** Delegate to AddressFamily.inaddrLength */
  command int inaddrLength (const struct sockaddr* addr);

  /** Delegate to AddressFamily.storeIpHeader.  The family of the destination
   * address is used for the encoding. */
  command int storeIpHeader (const struct sockaddr* saddr,
                             const struct sockaddr* daddr,
                             unsigned int len,
                             unsigned int protocol,
                             uint8_t* dst);

  /** Delegate to AddressFamily.ipMagicChecksum.  The family of the
   * destination address is used for the encoding.  */
  command uint16_t ipMagicChecksum (const struct sockaddr* saddr,
                                    const struct sockaddr* daddr,
                                    uint16_t len,
                                    uint8_t proto,
                                    uint16_t csum);

  /** Delegate to AddressFamily.addressEqual.  The family of addr1
   * is used.  If addr1 is null, returns FALSE */ 
  command bool addressEqual (const struct sockaddr* addr1,
                             const struct sockaddr* addr2);

  /** Delegate to AddressFamily.addressIsWildcard.  The family of addr
   * is used.  If addr is null, returns FALSE */ 
  command bool addressIsWildcard (const struct sockaddr* addr);

  /** Delegate to AddressFamily.addressIsMulticast.  The family of addr
   * is used.  If addr is null, returns FALSE */ 
  command bool addressIsMulticast (const struct sockaddr* addr);

  /** Delegate to AddressFamily.socketInGroup.  The family of addr
   * is used.  If addr is null, returns FALSE */ 
  command bool socketInGroup (const struct sockaddr* addr,
                              uint8_t socket_id,
                              oip_network_id_t nic_id1);

  /** Delegate to AddressFamily.acceptDeliveryTo.  The family of daddr
   * is used.  If daddr is null, returns FALSE. */ 
  command bool acceptDeliveryTo (const struct sockaddr* daddr,
                                 oip_network_id_t nic_id1);

  /** Delegate to AddressFamily.addressPrefixMatch.  The family of
   * addr is used.  If addr is null, returns FALSE. */
  command bool addressPrefixMatch (const struct sockaddr* addr,
                                   const uint8_t* prefix,
                                   unsigned int prefix_length_bits);

  /** Determine the number of bits in which the two addresses match.
   *
   * A value of -1 is returned to indicate incomparable addresses
   * (different or unrecognized families).
   */
  command int prefixMatchLength (const struct sockaddr* addr1,
                                 const struct sockaddr* addr2);

}
