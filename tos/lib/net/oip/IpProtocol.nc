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

/** Protocol-specific adaptations at the transport layer.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface IpProtocol {
  /** Return the IANA protocol number.  Primarily used to detect that
   * a particular protocol is not supported in the application, by
   * returning the value 0. */
  command uint8_t protocol ();

  /** Return TRUE iff the protocol incorporates port numbers in its
   * transport-layer header.
   */
  command bool usesPorts ();

  /** Locate the checksum within the transport-layer header.
   *
   * Protocols that support an upper-layer checksum indicate the
   * location of that checksum within the IP payload by providing a
   * non-negative return value.  Protocols that do not encode a
   * checksum anywhere in their network-layer payload should return
   * -1.
   */
  command int checksumOffset ();

  /** Extract protocol-relevant information from a transport-layer
   * header on packet reception.
   *
   * As an example, for protocols that include port information in the
   * transport-layer header, this command should update the ports
   * stored in the source and destination address data structures.
   *
   * Protocols that do not support a transport-layer header, or that
   * are generally used with raw sockets, do nothing but return zero.
   *
   * @param skb IP and link-layer information about the packet
   * (including source and address ports)
   *
   * @param data The start of the network-layer payload (i.e., the
   * start of the transport-layer header, if any)
   *
   * @param len the number of octets in the network-layer payload
   *
   * @return the number of octets in the transport-layer header
   */
  command int processTransportHeader (struct sk_buff* skb,
                                      const uint8_t* data,
                                      unsigned int len);

  /** Append a transport-layer header.
   *
   * Protocols that do not support a transport-layer header, or that
   * are generally used with raw sockets, do nothing but return zero.
   *
   * Common practice is to invoke this method once with a null dst to
   * determine the required space for the packet, then re-invoke it
   * once an outgoing packet buffer has been allocated.  Undefined
   * behavior may ensue if the parameters in the second invocation
   * changed from those in the first (specifically, there is no
   * guarantee that the buffer size requirements will be met).
   *
   * @param saddr The IP source address, including port information
   *
   * @param daddr The IP destination address, including port information
   *
   * @param len The length, in octets, of the transport-layer payload
   *
   * @param dst Where the transport-layer header should be written
   *
   * @return the number of octets in the transport-layer header.  If dst is
   * a null pointer, this may be a pre-calculated upper bound.
   */
  command int storeTransportHeader (const struct sockaddr* saddr,
                                    const struct sockaddr* daddr,
                                    unsigned int len,
                                    uint8_t* dst);
}
