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

/** Defines types and constants related to the TinyOS implementation
 * of IPV6 Stateless Address Autoconfiguration.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
#ifndef Ipv6Saa_H_
#define Ipv6Saa_H_

/** State of an address, as descrbed in RFC4862. */
typedef enum Ipv6SaaLeaseState_e {
  /** Address state invalid */
  SAALS_UNDEFINED = 0,
  /** Address is tentatively assigned.  Holds during Duplicate Address
   * Detection. */
  SAALS_tentative,
  /** Address is preferred. */
  SAALS_preferred,
  /** Deprecated addresses are past their preferred lifetime, but
   * within their valid lifetime. */
  SAALS_deprecated,
  /** Addresses are removed when they go beyond their valid
   * lifetime. */
  SAALS_removed,
  /** Addresses are also removed when the network interface they're
   * associated with goes down.  Note that while the NIC is down, its
   * interface identifier may change. */
  SAALS_nicDown,
} Ipv6SaaLeaseState_e;

#ifndef OIP_SAA_PREFIXES_PER_NIC
/** Number of autoconfigurable prefixes per NIC, not including the
 * link local prefix. */
#define OIP_SAA_PREFIXES_PER_NIC 2
#endif /* OIP_SAA_PREFIXES_PER_NIC */

/** Structure used internally to maintain IPv6 SAA prefixes.
 *
 * Not for end users.  The only reason this is in a public header is
 * we need to know how long it is in order to reserve space in a
 * fragment pool.  And to share it with unit test code.
 */
typedef struct ipv6SaaPrefixInfo_t_ {
  uint32_t preferred_timeout;
  uint32_t valid_timeout;
  const struct sockaddr_in6* address;
  uint8_t prefix_length_bits;
  uint8_t prefix[1];
} ipv6SaaPrefixInfo_t_;

#ifndef OIP_SAA_PREFIX_POOLSIZE_PER_NIC
/** The number of octets to reserve in the fragment pool for SAA
 * ipv6SaaPrefixInfo_t_ structures.
 *
 * The default reserves space for one structure per prefix, assuming 8
 * octets of prefix data, rounding to an even number of octets per
 * structure. */
#define OIP_SAA_PREFIX_POOLSIZE_PER_NIC (OIP_SAA_PREFIXES_PER_NIC * (2 * ((sizeof(ipv6SaaPrefixInfo_t_) + 7 + 1) / 2)))
#endif /* OIP_SAA_PREFIX_POOLSIZE_PER_NIC */

#endif /* Ipv6Saa_H_ */
