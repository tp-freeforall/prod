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

#include <stddef.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/udp.h>
#include <arpa/inet.h>

module Udp6P {
  provides {
    interface IpProtocol;
  }
  uses {
    interface AddressFamilies;
  }
} implementation {

  command uint8_t IpProtocol.protocol () { return IPPROTO_UDP; }
  command bool IpProtocol.usesPorts () { return TRUE; }
  command int IpProtocol.checksumOffset () { return offsetof(struct udphdr, check); }
  command int IpProtocol.processTransportHeader (struct sk_buff* skb,
                                                 const uint8_t* data,
                                                 unsigned int len)
  {
    const struct udphdr* uh = (const struct udphdr*)data;
    call AddressFamilies.setPort(skb->src, uh->source);
    call AddressFamilies.setPort(skb->dst, uh->dest);
    return sizeof(*uh);
  }
  command int IpProtocol.storeTransportHeader (const struct sockaddr* saddr,
                                               const struct sockaddr* daddr,
                                               unsigned int len,
                                               uint8_t* dst)
  {
    struct udphdr* uh = (struct udphdr*)dst;
    if (0 != dst) {
      uh->len = htons(sizeof(*uh) + len);
      uh->check = 0;
      uh->source = call AddressFamilies.getPort(saddr);
      uh->dest = call AddressFamilies.getPort(daddr);
    }
    return sizeof(*uh);
  }
}
