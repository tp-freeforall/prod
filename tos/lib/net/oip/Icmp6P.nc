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
#include <net/skbuff.h>
#include <netinet/in.h>
#include <netinet/icmp6.h>
#include <arpa/inet.h>
#include <stddef.h>

module Icmp6P {
  provides {
    interface Init;
    interface Icmp6;
    interface IpProtocol;
  }
  uses {
    interface Icmp6Dispatch[ uint8_t type ];
    interface IpSocketMsg;
    interface IpSocket;
  }
} implementation {

  struct sockaddr_in6 serverAddress_;

  command error_t Init.init ()
  {
    /* Bind to IN6ADDR_ANY (all zeros), port zero. */
    serverAddress_.sin6_family = AF_INET6;
    return call IpSocket.bind((struct sockaddr*)&serverAddress_);
  }

  command uint8_t IpProtocol.protocol () { return IPPROTO_ICMPV6; }
  command bool IpProtocol.usesPorts () { return FALSE; }
  command int IpProtocol.checksumOffset () { return offsetof(struct icmp6_hdr, icmp6_cksum); }
  command int IpProtocol.processTransportHeader (struct sk_buff* skb,
                                                 const uint8_t* data,
                                                 unsigned int len) { return 0; }
  command int IpProtocol.storeTransportHeader (const struct sockaddr* saddr,
                                               const struct sockaddr* daddr,
                                               unsigned int len,
                                               uint8_t* dst) { return 0; }


  default command int Icmp6Dispatch.type[ uint8_t type ] () { return -1; }
  default command void Icmp6Dispatch.process[ uint8_t type ] (struct sk_buff* skb,
                                                              struct icmp6_hdr* message,
                                                              unsigned int len) { }
  
  command error_t Icmp6.generate (uint8_t type,
                                  uint8_t code,
                                  uint32_t body_value,
                                  struct sockaddr* src,
                                  struct sockaddr* dst,
                                  const uint8_t* data,
                                  unsigned int len)
  {
    struct msghdr mhdr;
    struct icmp6_hdr oh;
    int niov = 0;
    struct iovec iov[2];
    error_t rc;

    oh.icmp6_type = type;
    oh.icmp6_code = code;
    oh.icmp6_cksum = 0;
    oh.icmp6_data32[0] = htonl(body_value);
    
    iov[niov].iov_base = &oh;
    iov[niov++].iov_len = sizeof(oh);
    if (data && (0 < len)) {
      iov[niov].iov_base = (uint8_t*)data;
      iov[niov++].iov_len = len;
    }

    memset(&mhdr, 0, sizeof(mhdr));
    mhdr.msg_name = src;
    mhdr.msg_namelen = 0;
    mhdr.msg_iov = iov;
    mhdr.msg_iovlen = niov;
    mhdr.msg_control = 0;
    mhdr.xmsg_sname = dst;

    rc = call IpSocketMsg.sendmsg(&mhdr, 0);
    return rc;
      
  }

  event void IpSocketMsg.recvmsg (const struct msghdr* message,
                                  int flags)
  {
    const uint8_t* data = message->msg_iov[0].iov_base;
    uint16_t len = message->msg_iov[0].iov_len;
    struct icmp6_hdr* h = (struct icmp6_hdr*)data;

    if (0 <= call Icmp6Dispatch.type[h->icmp6_type]()) {
      call Icmp6Dispatch.process[h->icmp6_type](message->msg_control, h, len);
    }
  }

}
