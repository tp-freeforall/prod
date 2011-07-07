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

#include <net/skbuff.h>

/** Interface implemented by any component that understands how to
 * process a specific IPv6 header.
 *
 * The Ipv6ProtocolC component may be used to bridge a protocol (as
 * opposed to IP) header into the IP stack.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com> */
interface Ipv6Header {
  /** IANA-controlled value identifying the header type.
   *
   * This corresponds to assigned Internet protocol numbers, listed at
   * http://www.iana.org/assignments/protocol-numbers */
  command int proto ();

  /** Process an IPv6 packet.
   *
   * @param skb The sk_buff structure providing information on the
   * lower level headers.
   *
   * @param payloadp On entry, points to the start of the header for
   * this message type.  On exit, points to the start of the next
   * header.  In all cases, the value is expected to be within the
   * original IP packet.
   *
   * @param nexthdrpp On entry, points to the location in the packet
   * where the nexthdr byte for this header is stored (generally,
   * outside the current payload).  On exit, points to the location in
   * the incoming payload at which the nexthdr field for the following
   * packet is stored; or a null pointer if this was the last header.
   *
   * @param payload_lenp On entry, a pointer to the valid length of
   * the incoming payload.  On exit, the length is updated to be the
   * length of the next header.  The value on exit is valid only if
   * the value of *nexthdrpp on exit is not null.
   *
   * @return TRUE iff the process method is implemented for this
   * header type.  The return value should be TRUE for all interface
   * implementations except a default implementation. */
  command bool process (struct sk_buff* skb,
                        const uint8_t** payloadp,
                        const uint8_t** nexthdrpp,
                        unsigned int *payload_lenp);
}
