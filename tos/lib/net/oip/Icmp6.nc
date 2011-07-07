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

/** Convenience interface to generate ICMP packets.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface Icmp6 {
  /** Build and transmit an ICMPv6 packet over the appropriate network
   * interface associated with the destination address.
   *
   * @param type the ICMP6 type field, e.g. ICMP_PARAM_PROB
   *
   * @param code The ICMP code field, e.g. ICMP_PARAM_PROB_NEXTHEADER
   *
   * @param body_value The value to be stored in the first 32-bit word
   * of the ICMP message, at offset 4.  The value is in host byte
   * order.  For example, the offset into the IP packet at which an
   * unrecognized header was found.
   *
   * @param src The source address for the ICMP message
   *
   * @param dst The destination of the ICMP message
   *
   * @param data Generally a pointer to the IP packet that motivated
   * the ICMP message.
   *
   * @param len The number of octets to be added to the ICMP packet.
   *
   * @return SUCCESS, or a NIC-specific error code
   */
  command error_t generate (uint8_t type,
                            uint8_t code,
                            uint32_t body_value,
                            struct sockaddr* src,
                            struct sockaddr* dst,
                            const uint8_t* data,
                            unsigned int len);
}
