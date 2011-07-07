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

#include <stdint.h>
#include <netinet/in.h>
#include "Ipv6Saa.h"

/** Support IPV6 Stateless Address Autoconfiguration as in RFC4862.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface Ipv6Saa {
  /** Define a prefix for address autoconfiguration.
   *
   * This command maintains the list of prefixes associated with an
   * interface.  Existing prefixes are updated by invoking this
   * command with non-zero lifetimes; a prefix is removed by invoking
   * this with a valid_lifetime of zero.
   *
   * A component that implements this interface should ensure that the
   * corresponding network interface is bound to addresses for each
   * prefix that is valid.
   *
   * @param prefix A bit sequence serving as the prefix portion of an
   * IPv6 address.
   *
   * @param prefix_length_bits The number of valid bits in the prefix.
   * If not a multiple of eight, the remaining least significant bits
   * of the last octet in the prefix are ignored.
   *
   * @param valid_lifetime As in an RFC4861 Prefix Information option
   *
   * @param preferred_lifetime As in an RFC4861 Prefix Information option
   */
  command error_t definePrefix (const uint8_t* prefix,
                                uint8_t prefix_length_bits,
                                uint32_t valid_lifetime,
                                uint32_t preferred_lifetime);

  /** Indicates a change in the state of an automatically configured
   * address.
   *
   * The event is raised whenever the network comes up or down, or if
   * the corresponding prefix is updated while the network is up.  At
   * the time of the event, the provided address will be bound to the
   * interface; depending on the lease state, it may be removed from
   * the interface immediately after the event completes.
   *
   * Note that no events are generated while the network is down.
   *
   * @param prefix As in definePrefix
   *
   * @param prefix_length_bits As in definePrefix
   *
   * @param addr The IPv6 address pointer that is bound to the
   * interface due to this prefix
   *
   * @param lease_state The state of the address
   */
  event void prefixChange (const uint8_t* prefix,
                           uint8_t prefix_length_bits,
                           const struct sockaddr_in6* addr,
                           Ipv6SaaLeaseState_e lease_state);
}
