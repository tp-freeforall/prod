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

/** Introspection to internal data structures and interfaces of IpSocketsP for unit testing.
 *
 * Internal use only.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface WhiteboxIpSockets {
  /* Expose the IpProtocol parameterized interface, with the default
   * implementation from IpSocketsP. */
  command uint8_t IpProtocol_protocol (uint8_t protocol);
  command bool IpProtocol_usesPorts (uint8_t protocol);
  command int IpProtocol_checksumOffset (uint8_t protocol);
  command int IpProtocol_processTransportHeader (uint8_t protocol,
                                                 struct sk_buff* skb,
                                                 const uint8_t* data,
                                                 unsigned int len);
  command int IpProtocol_storeTransportHeader (uint8_t protocol,
                                               const struct sockaddr* saddr,
                                               const struct sockaddr* daddr,
                                               unsigned int len,
                                               uint8_t* dst);

  command error_t SocketLevelOptions_getsockopt (int level,
                                                 uint8_t socket_id,
                                                 int option_name,
                                                 void* value,
                                                 socklen_t* option_len);
  command error_t SocketLevelOptions_setsockopt (int level,
                                                 uint8_t socket_id,
                                                 int option_name,
                                                 const void* value,
                                                 socklen_t option_len);
}
