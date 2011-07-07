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

#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <net/socket.h>
#include <net/checksum.h>
#include <netinet/icmp6.h>
#include <net/if.h>
#include "NetworkInterface.h"

module IpSocketsP {
  provides {
    interface IpSocketEntry;
    interface IpSocket[ uint8_t socket_id ];
    interface IpSocketMsg[ uint8_t socket_id ];
    interface IpDatagramSocket[ uint8_t socket_id ];
    interface IpConnectedSocket[ uint8_t socket_id ];
    interface SocketLevelOptions as SloSocket;
#if TEST_IPSOCKETS
    interface WhiteboxIpSockets;
#endif
  }
  uses {
    interface IpSocket_[ uint8_t socket_id ];
    interface AddressFamilies;
    interface NetworkInterface[ oip_network_id_t nic_id1 ];
    interface IpProtocol[ uint8_t protocol ];
    interface SocketLevelOptions[ int socket_level ];
    interface Icmp6;
    interface IpRouting;
  }
} implementation {
  const struct sockaddr* localName_[OIP_SOCKETS_MAX];
  const struct sockaddr* peerName_[OIP_SOCKETS_MAX];

  default command oip_network_id_t IpRouting.nicForDestination (const struct sockaddr* addr)
  {
    oip_network_id_t nic_id1 = call AddressFamilies.getNicId(addr);
    if (0 == nic_id1) {
      nic_id1 = 1;
    }
    return nic_id1;
  }

  default command error_t SocketLevelOptions.getsockopt[ int level ] (uint8_t socket_id,
                                                                      int option_name,
                                                                      void* value,
                                                                      socklen_t* option_len) { return FAIL; }
  default command error_t SocketLevelOptions.setsockopt[ int level ] (uint8_t socket_id,
                                                                      int option_name,
                                                                      const void* value,
                                                                      socklen_t option_len) { return FAIL; }

  command error_t IpSocket.getsockopt[ uint8_t socket_id ] (int level,
                                                            int option_name,
                                                            void* value,
                                                            socklen_t* option_len)
  {
    return call SocketLevelOptions.getsockopt[level](socket_id, option_name, value, option_len);
  }

  command error_t IpSocket.setsockopt[ uint8_t socket_id ] (int level,
                                                            int option_name,
                                                            const void* value,
                                                            socklen_t option_len)
  {
    return call SocketLevelOptions.setsockopt[level](socket_id, option_name, value, option_len);
  }

  event void NetworkInterface.interfaceState[ oip_network_id_t nic_id1 ] (oip_nic_state_t state) { }

  default command uint8_t IpSocket_.id[ uint8_t socket_id ] () { return 255; }
  default command uint8_t IpSocket_.domain[ uint8_t socket_id ] () { return 0; }
  default command uint8_t IpSocket_.type[ uint8_t socket_id ] () { return 0; }
  default command uint8_t IpSocket_.protocol[ uint8_t socket_id ] () { return 0; }

  default command uint8_t IpProtocol.protocol[ uint8_t protocol ] () { return 0; }
  default command bool IpProtocol.usesPorts[ uint8_t protocol ] () { return FALSE; }
  default command int IpProtocol.checksumOffset[ uint8_t protocol ] () { return -1; }
  default command int IpProtocol.processTransportHeader[ uint8_t protocol ] (struct sk_buff* skb,
                                                                             const uint8_t* data,
                                                                             unsigned int len) { return 0; }
  default command int IpProtocol.storeTransportHeader[ uint8_t protocol ] (const struct sockaddr* saddr,
                                                                           const struct sockaddr* daddr,
                                                                           unsigned int len,
                                                                           uint8_t* dst) { return 0; }
  
#if TEST_IPSOCKETS
  command uint8_t WhiteboxIpSockets.IpProtocol_protocol (uint8_t protocol) { return call IpProtocol.protocol[protocol](); }
  command bool WhiteboxIpSockets.IpProtocol_usesPorts (uint8_t protocol) { return call IpProtocol.usesPorts[protocol](); }
  command int WhiteboxIpSockets.IpProtocol_checksumOffset (uint8_t protocol) { return call IpProtocol.checksumOffset[protocol](); }
  command int WhiteboxIpSockets.IpProtocol_processTransportHeader (uint8_t protocol,
                                                                   struct sk_buff* skb,
                                                                   const uint8_t* data,
                                                                   unsigned int len) { return call IpProtocol.processTransportHeader[protocol](skb, data, len); }
  command int WhiteboxIpSockets.IpProtocol_storeTransportHeader (uint8_t protocol,
                                                                 const struct sockaddr* saddr,
                                                                 const struct sockaddr* daddr,
                                                                 unsigned int len,
                                                                 uint8_t* dst) { return call IpProtocol.storeTransportHeader[protocol](saddr, daddr, len, dst); }
  command error_t WhiteboxIpSockets.SocketLevelOptions_getsockopt (int level,
                                                                   uint8_t socket_id,
                                                                   int option_name,
                                                                   void* value,
                                                                   socklen_t* option_len)
  {
    return call SocketLevelOptions.getsockopt[level](socket_id, option_name, value, option_len);
  }

  command error_t WhiteboxIpSockets.SocketLevelOptions_setsockopt (int level,
                                                                   uint8_t socket_id,
                                                                   int option_name,
                                                                   const void* value,
                                                                   socklen_t option_len)
  {
    return call SocketLevelOptions.setsockopt[level](socket_id, option_name, value, option_len);
  }

#endif /* TEST_IPSOCKETS */

  command error_t SloSocket.getsockopt (uint8_t socket_id,
                                        int option_name,
                                        void* value,
                                        socklen_t* option_len)
  {
    error_t rv;
    
    if (socket_id >= OIP_SOCKETS_MAX) {
      return EINVAL;
    }
    if (sizeof(int) > *option_len) {
      return EINVAL;
    }
    *option_len = sizeof(int);
    rv = EINVAL;
    switch (option_name) {
      case SO_TYPE:
        *(int*)value = call IpSocket_.type[socket_id]();
        rv = SUCCESS;
        break;
      default:
        break;
    }
    return rv;
  }
  command error_t SloSocket.setsockopt (uint8_t socket_id,
                                        int option_name,
                                        const void* value,
                                        socklen_t option_len)
  {
    if (socket_id >= OIP_SOCKETS_MAX) {
      return EINVAL;
    }
    switch (option_name) {
      case SO_TYPE:
        /* Sorry, can't change the type of a socket */
        return EINVAL;
    }
    return EINVAL;
  }

  command int IpSocket.descriptor[ uint8_t socket_id ] () { return (socket_id < OIP_SOCKETS_MAX) ? socket_id : -1; }
  command int IpSocketMsg.descriptor[ uint8_t socket_id ] () { return (socket_id < OIP_SOCKETS_MAX) ? socket_id : -1; }
  command int IpDatagramSocket.descriptor[ uint8_t socket_id ] () { return (socket_id < OIP_SOCKETS_MAX) ? socket_id : -1; }
  command int IpConnectedSocket.descriptor[ uint8_t socket_id ] () { return (socket_id < OIP_SOCKETS_MAX) ? socket_id : -1; }

  command error_t IpSocket.bind[ uint8_t socket_id ] (const struct sockaddr* address)
  {
    if (address && localName_[socket_id]) {
      return EALREADY;
    }
    localName_[socket_id] = address;
    return SUCCESS;
  }

  command const struct sockaddr* IpSocket.getsockname[ uint8_t socket_id ] ()
  {
    return localName_[socket_id];
  }

  command error_t IpSocket.connect[ uint8_t socket_id ] (const struct sockaddr* address)
  {
    if (address && peerName_[socket_id]) {
      return EALREADY;
    }
    peerName_[socket_id] = address;
    return SUCCESS;
  }

  command const struct sockaddr* IpSocket.getpeername[ uint8_t socket_id ] ()
  {
    return peerName_[socket_id];
  }

  uint16_t csum_partial_copy_fast (const void* src,
                                   void* dst,
                                   unsigned int len,
                                   uint16_t csum) @C()
  {
    register const uint16_t* sp = (const uint16_t*)src;
    register uint16_t* dp = (uint16_t*)dst;
    while (2 <= len) {
      csum += *sp;
      if (dp) {
        *dp++ = *sp;
      }
      csum += (csum < *sp++);
      len -= 2;
    }
    if (0 < len) {
      union {
        uint8_t u8[2];
        uint16_t u16;
      } un;
      un.u8[0] = *(const uint8_t*)sp;;
      if (dp) {
        *(uint8_t*)dp = un.u8[0];
      }
      un.u8[1] = 0;
      csum += un.u16;
      csum += (csum < un.u16);
    }
    return csum;
  }

  uint16_t csum_partial_fast (const void* src,
                              unsigned int len,
                              uint16_t csum) @C()
  {
    return csum_partial_copy_fast(src, 0, len, csum);
  }

  uint8_t packetBuffer_[256];

  command error_t IpConnectedSocket.send[ uint8_t socket_id ] (const void* buffer,
                                                               size_t length,
                                                               int flags)
  {
    if (! peerName_[socket_id]) {
      return FAIL;
    }
    return call IpDatagramSocket.sendto[socket_id](buffer, length, flags, peerName_[socket_id], 0);
  }

  command error_t IpDatagramSocket.sendto[ uint8_t socket_id ] (const void* buffer,
                                                                size_t length,
                                                                int flags,
                                                                const struct sockaddr* dest_addr,
                                                                socklen_t dest_len)
  {
    struct msghdr mhdr;
    struct iovec iov;
    
    iov.iov_base = (void*)buffer;
    iov.iov_len = length;

    memset(&mhdr, 0, sizeof(mhdr));
    mhdr.msg_name = (void*)dest_addr;
    mhdr.msg_namelen = dest_len;
    mhdr.msg_iov = &iov;
    mhdr.msg_iovlen = 1;

    return call IpSocketMsg.sendmsg[socket_id](&mhdr, flags);
  }

  /** Determine the address to use as the source of the outgoing packet.
   *
   * Based on RFC3484, this is the address bound to the outgoing NIC
   * that has the longest matching prefix with the destination
   * address.
   *
   * If no bound address is in the proper address family, this returns
   * a null pointer. */
  const struct sockaddr*
  sourceForDestination_ (const struct sockaddr* daddr,
                         oip_network_id_t nic_id1)
  {
    const struct sockaddr* const* addresses;
    int num_addresses;
    const struct sockaddr* saddr = 0;
    int best_len = -1;

    num_addresses = call NetworkInterface.boundAddresses[nic_id1](&addresses);
    while (0 < num_addresses--) {
      const struct sockaddr* cp = addresses[num_addresses];
      int match_len = call AddressFamilies.prefixMatchLength(daddr, cp);
      if (match_len > best_len) {
        best_len = match_len;
        saddr = cp;
      }
    }
    return saddr;
  }

  command error_t IpSocketMsg.sendmsg[ uint8_t socket_id ] (const struct msghdr* message,
                                                            int flags)
  {
    union {
      struct sockaddr_storage ss;
      struct sockaddr_in6 s6;   /* To eliminate gcc alignment warning */
      struct sockaddr sa;
    } sourceu;
    uint8_t socket_type = call IpSocket_.type[socket_id]();
    const struct sockaddr* lna;
    const struct sockaddr* saddr;
    const struct sockaddr* daddr;
    int nic_id1;
    int i;
    int transport_header_len;
    uint8_t* transport_header;
    int network_header_len;
    int link_header_len;
    uint16_t payload_len;
    int checksum_offset;
    uint8_t proto;
    uint8_t* buffer = packetBuffer_;
    const unsigned int buffer_length = sizeof(packetBuffer_);
    uint8_t* dp = buffer;
    error_t rc;
    
    proto = call IpSocket_.protocol[socket_id]();
    if (IPPROTO_RAW == proto) {
      struct sk_buff* skb = message->msg_control;
      if (0 == skb) {
        return EINVAL;
      }
      proto = skb->proto;
    }

    daddr = (struct sockaddr*)message->msg_name;
    if (! daddr) {
      return EINVAL;
    }

    lna = localName_[socket_id];
    if (lna && (lna->sa_family != daddr->sa_family)) {
      return EINVAL;
    }

    nic_id1 = call IpRouting.nicForDestination(daddr);

    saddr = (struct sockaddr*)message->xmsg_sname;
    if (saddr) {
      if (saddr->sa_family != daddr->sa_family) {
        return EINVAL;
      }
    } else {
      saddr = sourceForDestination_(daddr, nic_id1);
      if (! saddr) {
        return EINVAL;
      }
      if (lna) {
        memcpy(&sourceu.ss, saddr, call AddressFamilies.sockaddrLength(saddr->sa_family));
        call AddressFamilies.setPort(&sourceu.sa, call AddressFamilies.getPort(lna));
        saddr = &sourceu.sa;
      }
    }

    /* Determine the user payload length */
    payload_len = 0;
    for (i = 0; i < message->msg_iovlen; ++i) {
      struct iovec* iovp = message->msg_iov + i;
      payload_len += iovp->iov_len;
    }

    /* Does the protocol use an IP-level checksum?  If not (offset is
     * negative), we'll skip those steps. */
    checksum_offset = call IpProtocol.checksumOffset[proto]();

    if (SOCK_RAW == socket_type) {
      /* For raw sockets, transport header comes from the msghdr. */
      transport_header_len = 0;
    } else {
      /* Determine the size of the protocol-specific header */
      transport_header_len = call IpProtocol.storeTransportHeader[proto] (saddr, daddr, payload_len, 0);
      if (0 > transport_header_len) {
        return FAIL;
      }
    }
    
    /* Determine the size of the IP header */
    network_header_len = call AddressFamilies.storeIpHeader(saddr, daddr, transport_header_len + payload_len, proto, 0);
    if (0 > network_header_len) {
      return FAIL;
    }

    /* Determine the size of the link header */
    link_header_len = call NetworkInterface.storeLinkHeader[nic_id1](saddr, daddr, network_header_len + transport_header_len + payload_len, 0);
    if (0 > link_header_len) {
      return -link_header_len;
    }
      
    /* Here eventually dynamically allocate storage */
    if (buffer_length < (link_header_len + network_header_len + transport_header_len + payload_len)) {
      return ENOMEM;
    }
      
    /* Store the link-layer header */
    link_header_len = call NetworkInterface.storeLinkHeader[nic_id1](saddr, daddr, network_header_len + transport_header_len + payload_len, dp);
    dp += link_header_len;
      
    /* Append the network (IP) header. */
    i = call AddressFamilies.storeIpHeader(saddr, daddr, transport_header_len + payload_len, proto, dp); 
    dp += i;
    transport_header = dp;

    if (IPPROTO_RAW != call IpSocket_.protocol[socket_id]()) {
      uint16_t csum = 0;

      /* Calculate the IP header's checksum (note: use the
       * pseudo-header calculation for this, not the actual header
       * which includes things like hop count that aren't relevant to
       * the checksum) */
      if (0 <= checksum_offset) {
        csum = call AddressFamilies.ipMagicChecksum(saddr, daddr, transport_header_len + payload_len, proto, 0);
      }

      /* Append the protocol (transport) header.  Calculate its
       * checksum, if it exists. */
      i = call IpProtocol.storeTransportHeader[proto](saddr, daddr, payload_len, dp);
      if (0 < i) {
        if (0 <= checksum_offset) {
          csum = csum_partial_fast(dp, i, csum);
        }
        dp += i;
      }

      /* Does the protocol use a protocol-level checksum?  If so,
       * calculate and store it; otherwise just copy the payload into
       * the transmission buffer (until we support gather send at the
       * link layer) */
      if (0 <= checksum_offset) {
        uint16_t* cksump = (uint16_t*)(transport_header + checksum_offset);
        
        for (i = 0; i < message->msg_iovlen; ++i) {
          struct iovec* iovp = message->msg_iov + i;
          
          csum = csum_partial_copy_fast(iovp->iov_base, dp, iovp->iov_len, csum);
          payload_len += iovp->iov_len;
          dp += iovp->iov_len;
          
        }
        *cksump = csum_fold(csum);
        if (! *cksump) {
          *cksump = CSUM_MANGLED_0;
        }
      } else {
        for (i = 0; i < message->msg_iovlen; ++i) {
          struct iovec* iovp = message->msg_iov + i;
	  memcpy(dp, iovp->iov_base, iovp->iov_len);
	  dp += iovp->iov_len;
        }
      }
    } else {
      for (i = 0; i < message->msg_iovlen; ++i) {
        struct iovec* iovp = message->msg_iov + i;
        memcpy(dp, iovp->iov_base, iovp->iov_len);
        dp += iovp->iov_len;
      }
    }

    rc = call NetworkInterface.transmit[nic_id1](buffer, dp - buffer);
    return rc;
  }

  default event void IpConnectedSocket.recv[ uint8_t socket_id ] (const void* buffer,
                                                                  size_t length,
                                                                  int flags) { }

  default event void IpDatagramSocket.recvfrom[ uint8_t socket_id ] (const void* buffer,
                                                                     size_t length,
                                                                     int flags,
                                                                     const struct sockaddr* address,
                                                                     socklen_t address_len)
  {
    if (call AddressFamilies.addressEqual(address, peerName_[socket_id])) {
      signal IpConnectedSocket.recv[socket_id](buffer, length, flags);
    }
  }

  default event void IpSocketMsg.recvmsg[ uint8_t socket_id ] (const struct msghdr* message,
                                                               int flags)
  {
    struct sk_buff* skb = message->msg_control;
    const void* buffer = message->msg_iov->iov_base;
    size_t length = message->msg_iov->iov_len;
    const struct sockaddr* sap = skb->src;
    signal IpDatagramSocket.recvfrom[socket_id](buffer, length, flags, skb->src, call AddressFamilies.sockaddrLength(sap->sa_family));
  }

  command error_t IpSocketEntry.deliver (struct sk_buff* skb,
                                         uint16_t proto,
                                         const uint8_t* data,
                                         unsigned int len)
  {
    int si;
    struct msghdr message_raw;
    struct msghdr message_cooked;
    int payload_offset;
    struct iovec iov_raw;
    struct iovec iov_cooked;
    bool delivered = FALSE;
    int checksum_offset;

#if TRACE_IP_RX
    printf("IPSOCK len=%u proto=%u\r\n\tsrc=%s\r\n", len, proto, getnameinfo(skb->src));
    printf("\tdst=%s\r\n", getnameinfo(skb->dst));
#endif

    /* Does the protocol use an IP-level checksum?  If not (offset is
     * negative), we'll skip those steps. */
    checksum_offset = call IpProtocol.checksumOffset[proto]();
    if (0 <= checksum_offset) {
      uint16_t csum;
      csum = *(uint16_t*)(data + checksum_offset);
      if (0 != csum) {
        csum = call AddressFamilies.ipMagicChecksum(skb->src, skb->dst, len, proto, 0);
        csum = csum_partial_fast(data, len, csum);
        if (0 != csum_fold(csum)) {
#if TRACE_IP_RX
          printf("checksum failed: rx %04x calc %04x\r\n",
                 *(uint16_t*)(data + checksum_offset),
                 csum_fold(csum));
#endif /* TRACE_IP_RX */
          // @TODO@ Record in interface statistics
          return FAIL;
        }
      }
    }

    /* If appropriate, extract port information from the protocol
     * message and use it to update the send and receive addresses. */
    payload_offset = call IpProtocol.processTransportHeader[proto](skb, data, len);

    iov_raw.iov_base = (uint8_t*)data;
    iov_raw.iov_len = len;
    iov_cooked.iov_base = payload_offset + (uint8_t*)data;
    iov_cooked.iov_len = len - payload_offset;

    memset(&message_raw, 0, sizeof(message_raw));
    message_raw.msg_iov = &iov_raw;
    message_raw.msg_iovlen = 1;
    message_raw.msg_control = skb;
    message_raw.msg_controllen = sizeof(*skb);
    message_raw.msg_name = skb->src;
    message_raw.msg_namelen = call AddressFamilies.sockaddrLength(skb->src->sa_family);

    message_cooked = message_raw;
    message_cooked.msg_iov = &iov_cooked;

    for (si = 0; si < OIP_SOCKETS_MAX; ++si) {
      bool is_wildcard;
      bool is_addressed;
      uint8_t socket_type = call IpSocket_.type[si]();
      uint16_t socket_proto = call IpSocket_.protocol[si]();

#if TRACE_IP_RX
      printf("rx si %d proto %d: ", si, socket_proto);
#endif /* TRACE_IP_RX */
      /* Deliver only if socket deals in this protocol */
      if ((socket_proto != proto) && (SOCK_RAW != socket_type)) {
#if TRACE_IP_RX
        printf("bad prot\r\n");
#endif /* TRACE_IP_RX */
        continue;
      }

      /* No delivery to unbound sockets, not even raw ones. */
      if (! localName_[si]) {
#if TRACE_IP_RX
        printf("unbound\r\n");
#endif /* TRACE_IP_RX */
        continue;
      }

      /* Only deliver if socket is bound to wildcard address, or
       * packet is addressed to bound address. */
      is_wildcard = call AddressFamilies.addressIsWildcard(localName_[si]);
      is_addressed = call AddressFamilies.addressEqual(skb->dst, localName_[si]);
      if ((! is_wildcard) && (! is_addressed)) {
#if TRACE_IP_RX
        printf("wc %d addr %d\r\n", is_wildcard, is_addressed);
#endif /* TRACE_IP_RX */
        continue;
      }

      /* Deliver with or without the transport-layer header removed */
      if (SOCK_RAW == socket_type) {
#if TRACE_IP_RX
        printf("raw\r\n");
#endif /* TRACE_IP_RX */
        signal IpSocketMsg.recvmsg[si](&message_raw, 0);
      } else {
        /* Further checks apply to non-raw sockets:
         * - port must match
         * - @TODO if destination is multicast address, socket must be joined to group */
        /* If not a raw socket, better match the port too. */
        if (call IpProtocol.usesPorts[socket_proto]()) {
          uint16_t dport_nbo = call AddressFamilies.getPort(skb->dst);
          uint16_t lport_nbo = call AddressFamilies.getPort(localName_[si]);
          if (dport_nbo != lport_nbo) {
#if TRACE_IP_RX
            printf("port %u %u\r\n", ntohs(dport_nbo), ntohs(lport_nbo));
#endif /* TRACE_IP_RX */
            continue;
          }
        }
        if ((call AddressFamilies.addressIsMulticast(skb->dst))
            && (! call AddressFamilies.socketInGroup(skb->dst, si, skb->nic_id))) {
#if TRACE_IP_RX
          printf("not joined to dst %s\r\n", getnameinfo(skb->dst));
#endif /* TRACE_IP_RX */
          continue;
        }
#if TRACE_IP_RX
        printf("cooked\r\n");
#endif /* TRACE_IP_RX */
        signal IpSocketMsg.recvmsg[si](&message_cooked, 0);
      }
      delivered = TRUE;
    }
    if (! delivered) {
      call Icmp6.generate(ICMP6_DST_UNREACH, ICMP6_DST_UNREACH_ADMIN, 0,
                          skb->dst, skb->src,
                          data, len);
    }
    return SUCCESS;
  }

}
