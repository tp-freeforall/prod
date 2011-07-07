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

/** Support for an RFC4193-conformant Unique Local Address prefix in OSIAN.
 *
 * RFC4193 describes a mechanism for defining a /48 prefix in the IPv6
 * global address space that can be used to provide local addresses
 * for nodes that must communicate beyond a local link.  For the
 * convenience of OSIAN users, this module specifies such an address,
 * as well as subnets that can be used to.
 *
 * Please ensure the OSIAN ULA prefix is not routed beyond your
 * administrative domain.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

#ifndef OSIAN_OIP_NET_OSIAN_H_
#define OSIAN_OIP_NET_OSIAN_H_

/** Initializer for a uint8_t[6] definition holding the OSIAN ULA /48. */
#define OSIAN_ULA_48_INIT { 0xfd, 0x41, 0x42, 0x42, 0x0e, 0x88, }

enum {
  /** Used as the subnet part of a /64 prefix associated with the
   * gateway machine.  Addresses in this prefix are used by nodes on
   * other links (such as a radio link) to contact a full-function
   * device presumed able to connect directly to the internet. */
  OSIAN_ULA_SUBNET_GATEWAY = 1,

  /** Used as the subnet part of a /64 prefix associated with a radio
   * network running the Ipv6Ieee154C interface. */
  OSIAN_ULA_SUBNET_IEEE154 = 2,

  /* TBR: Additional subnets for other MACs like tkn154 or rf1a
   * direct */
};

#endif /* OSIAN_OIP_NET_OSIAN_H_ */
