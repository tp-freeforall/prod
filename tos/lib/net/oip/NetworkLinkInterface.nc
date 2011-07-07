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

/** Implement the interface-specific aspects of a
 * link-layer/network-layer bridge.
 *
 * @NOTE: The transmit interface will change in the future to permit
 * split-phase transmission with shared buffers, and gather-style
 * transmissions.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface NetworkLinkInterface {

  /** Create and store the link-layer header, if any.
   *
   * It is assumed that the network can generate link-layer source and
   * destination addresses from the information presented in the IP
   * source and destination addresses.  Interfaces that do not
   * incorporate a link header, or do not need hints from the IP
   * addresses to determine link-layer addresses, are entitled to hide
   * the existence of any link layer header by having this command
   * return zero.
   *
   * Common practice is to invoke this method once with a null dst to
   * determine the required space for the packet, then re-invoke it
   * once an outgoing packet buffer has been allocated.  Undefined
   * behavior may ensue if the parameters in the second invocation
   * changed from those in the first (specifically, there is no
   * guarantee that the buffer size requirements will be met).
   *
   * @param saddr the IP layer source address
   *
   * @param daddr The IP layer destination address
   *
   * @param len The number of octets in the entire IP packet,
   * including IP headers
   *
   * @param dst Where the link-layer header should be written.
   *
   * @return the number of octets in the link-layer header.  If dst is
   * a null pointer, this may be a pre-calculated upper bound.  A
   * negative value indicates that the header could not be
   * initialized: the value is a negated TinyOS error code.
   */
  command int storeLinkHeader (const struct sockaddr* saddr,
                               const struct sockaddr* daddr,
                               unsigned int len,
                               uint8_t* dst);

  /** Submit a pre-built message, including any link-layer header
   * managed via storeLinkHeader, to the link layer.
   *
   * @TODO At the moment, ownership of the message buffer is not
   * transferred to the link layer: the link layer must make a copy if
   * it cannot transmit the message in its entirety during this call.
   * This will change.
   *
   * @param message Pointer to the start of the prepared message
   *
   * @param len length of the message, in octets
   *
   * @return a link-layer--specific success or error code. */
  command error_t transmit (const void* message,
                            unsigned int len);

  /** Provide metadata on a received packet.
   *
   * This allows users of the interface to obtain information on
   * packet reception, such as RSSI for network links involving a
   * radio.  The provided value must be persistent, as it will be
   * cached and returned to the user.
   *
   * @note This event should be signaled before the packet is
   * delivered via IpEntry.deliver.
   *
   * @param rx_metadata Pointer to a link-specific structure holding
   * information on a newly received packet.
   */
  event void provideRxMetadata (const void* rx_metadata);

}
