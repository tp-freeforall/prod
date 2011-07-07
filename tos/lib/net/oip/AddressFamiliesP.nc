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
#include <arpa/inet.h>
#include <stdio.h>

module AddressFamiliesP {
  provides {
    interface AddressFamilies;
  }
  uses {
    interface AddressFamily as AddressFamily[ uint8_t family ];
  }
} implementation {

  const char* inet_ntop_in6 (const struct in6_addr* ip)
  {
    static char buffer[8*5+1]; /* 8 4-char quads, 7 colon separators, 1 EOS */
    char *bp = buffer;
    const uint16_t* sp;
    const uint16_t* spe;
    int did_zero = 0;
    int zc = 0;
    int nzc = 0;
  
    if (! ip) {
      *bp = 0;
      return bp;
    }
    sp = (const uint16_t*)ip->s6_addr;
    spe = sp + 8;
    while (sp < spe) {
      zc = 0;
      /* Emit text for all leading non-zero groups */
      while ((sp < spe) && (did_zero || (0 != *sp))) {
        bp += sprintf(bp, "%x:", ntohs(*sp++));
        ++nzc;
      }
      if ((sp < spe) && (! did_zero)) {
        /* See how many consecutive zeros are present.  We know there's
         * at least one. */
        while ((sp < spe) && (0 == *sp)) {
          ++zc;
          ++sp;
        }
        did_zero = (1 < zc);
        if (! did_zero) {
          /* Only one.  Don't bother with the shorthand for it. */
          *bp++ = '0';
        } else if (0 == nzc) {
          /* Short-hand zeros start the sequence */
          *bp++ = ':';
        }
        *bp++ = ':';
      }
    }
    if ((0 < nzc) && (0 == zc)) {
      /* Kill the trailing : from the last group */
      --bp;
    }
    /* Put EOS at right position (if all zeroes, there isn't one yet) */
    *bp = 0;
    return buffer;
  }

  const char* inet_ntop (int af, const void* src) @C()
  {
    if (AF_INET6 == af) {
      return inet_ntop_in6((const struct in6_addr*)src);
    }
    return 0;
  }

  const char* getnameinfo (const struct sockaddr* addr) @C()
  {
    return inet_ntop(addr->sa_family, call AddressFamily.inaddrPointer[addr->sa_family](addr));
  }

  command socklen_t AddressFamilies.sockaddrLength (sa_family_t family) { return call AddressFamily.sockaddrLength[family](); }

  command const uint8_t* AddressFamilies.inaddrPointer (const struct sockaddr* addr) { return call AddressFamily.inaddrPointer[addr->sa_family](addr); }

  command int AddressFamilies.inaddrLength (const struct sockaddr* addr) { return call AddressFamily.inaddrLength[addr->sa_family](); }

  command void AddressFamilies.setPort (struct sockaddr* addr, uint16_t port) { return call AddressFamily.setPort[addr->sa_family](addr, port); }

  command uint16_t AddressFamilies.getPort (const struct sockaddr* addr) { return call AddressFamily.getPort[addr->sa_family](addr); }

  command oip_network_id_t AddressFamilies.getNicId (const struct sockaddr* addr) { return call AddressFamily.getNicId[addr->sa_family](addr); }

  command void AddressFamilies.setNicId (struct sockaddr* addr, oip_network_id_t nic_id1) { return call AddressFamily.setNicId[addr->sa_family](addr, nic_id1); }

  command int AddressFamilies.storeIpHeader (const struct sockaddr* saddr,
                                             const struct sockaddr* daddr,
                                             unsigned int len,
                                             unsigned int protocol,
                                             uint8_t* dst)
  {
    return call AddressFamily.storeIpHeader[daddr->sa_family](saddr, daddr, len, protocol, dst);
  }

  command uint16_t AddressFamilies.ipMagicChecksum (const struct sockaddr* saddr,
                                                  const struct sockaddr* daddr,
                                                  uint16_t len,
                                                  uint8_t proto,
                                                  uint16_t csum)
  {
    return call AddressFamily.ipMagicChecksum[daddr->sa_family](saddr, daddr, len, proto, csum);
  }

  command bool AddressFamilies.addressEqual (const struct sockaddr* addr1,
                                             const struct sockaddr* addr2)
  {
    if (! addr1) {
      return FALSE;
    }
    return call AddressFamily.addressEqual[addr1->sa_family](addr1, addr2);
  }

  command bool AddressFamilies.addressIsWildcard (const struct sockaddr* addr)
  {
    if (! addr) {
      return FALSE;
    }
    return call AddressFamily.addressIsWildcard[addr->sa_family](addr);
  }

  command bool AddressFamilies.addressIsMulticast (const struct sockaddr* addr)
  {
    if (! addr) {
      return FALSE;
    }
    return call AddressFamily.addressIsMulticast[addr->sa_family](addr);
  }

  command bool AddressFamilies.socketInGroup (const struct sockaddr* addr,
                                              uint8_t socket_id,
                                              oip_network_id_t nic_id1)
  {
    if (! addr) {
      return FALSE;
    }
    return call AddressFamily.socketInGroup[addr->sa_family](addr, socket_id, nic_id1);
  }

  command bool AddressFamilies.acceptDeliveryTo (const struct sockaddr* daddr,
                                                oip_network_id_t nic_id1)
  {
    if (! daddr) {
      return FALSE;
    }
    return call AddressFamily.acceptDeliveryTo[daddr->sa_family](daddr, nic_id1);
  }

  command bool AddressFamilies.addressPrefixMatch (const struct sockaddr* addr,
                                                   const uint8_t* prefix,
                                                   unsigned int prefix_length_bits)
  {
    if (! addr) {
      return FALSE;
    }
    return call AddressFamily.addressPrefixMatch[addr->sa_family](addr, prefix, prefix_length_bits);
  }

  command int AddressFamilies.prefixMatchLength (const struct sockaddr* addr1,
                                                 const struct sockaddr* addr2)
  {
    const uint8_t* p1;
    const uint8_t* p2;
    int prefix_len_bits;
    int match_len_bits;
    
    if ((! addr1) || (! addr2) || (addr1->sa_family != addr2->sa_family)) {
      return -1;
    }
    p1 = call AddressFamily.inaddrPointer[addr1->sa_family](addr1);
    p2 = call AddressFamily.inaddrPointer[addr2->sa_family](addr2);
    prefix_len_bits = 8 * call AddressFamily.inaddrLength[addr1->sa_family]();
    match_len_bits = 0;
    while (match_len_bits < prefix_len_bits) {
      if (*p1 != *p2) {
        break;
      }
      ++p1;
      ++p2;
      match_len_bits += 8;
    }
    if (match_len_bits < prefix_len_bits) {
      uint8_t bit_mask = 0x80;
      while ((bit_mask & *p1) == (bit_mask & *p2)) {
        ++match_len_bits;
        bit_mask >>= 1;
      }
    }
    return match_len_bits;
  }

  default command sa_family_t AddressFamily.family[ uint8_t family ] () { return 0; }
  default command socklen_t AddressFamily.sockaddrLength[ uint8_t family ] () { return 0; }
  default command int AddressFamily.inaddrLength[ uint8_t family ] () { return 0; }
  default command void AddressFamily.setPort[ uint8_t family ] (struct sockaddr* addr, uint16_t port) { }
  default command uint16_t AddressFamily.getPort[ uint8_t family ] (const struct sockaddr* addr) { return 0; }
  default command oip_network_id_t AddressFamily.getNicId[ uint8_t family ] (const struct sockaddr* addr) { return 0; }
  default command void AddressFamily.setNicId[ uint8_t family ] (struct sockaddr* addr, oip_network_id_t nic_id1) { }
  default command const uint8_t* AddressFamily.inaddrPointer[ uint8_t family ] (const struct sockaddr* addr) { return 0; }
  default command uint16_t AddressFamily.ipMagicChecksum[ uint8_t family ] (const struct sockaddr* saddr,
                                                                          const struct sockaddr* daddr,
                                                                          uint16_t len,
                                                                          uint8_t proto,
                                                                          uint16_t csum) { return 0; }
  default command int AddressFamily.storeIpHeader[ uint8_t family ] (const struct sockaddr* saddr,
                                                                     const struct sockaddr* daddr,
                                                                     unsigned int len,
                                                                     unsigned int protocol,
                                                                     uint8_t* dst) { return -1; }
  default command bool AddressFamily.addressEqual[ uint8_t family ] (const struct sockaddr* addr1,
                                                                     const struct sockaddr* addr2) { return FALSE; }
  default command bool AddressFamily.addressIsWildcard[ uint8_t family ] (const struct sockaddr* addr) { return FALSE; }
  default command bool AddressFamily.addressIsMulticast[ uint8_t family ] (const struct sockaddr* addr) { return FALSE; }
  default command bool AddressFamily.socketInGroup[ uint8_t family ] (const struct sockaddr* addr,
                                                                      uint8_t socket_id,
                                                                      oip_network_id_t nic_id1) { return FALSE; }
  default command bool AddressFamily.acceptDeliveryTo[ uint8_t family ] (const struct sockaddr* daddr,
                                                                         oip_network_id_t nic_id1) { return FALSE; }
  default command bool AddressFamily.addressPrefixMatch[ uint8_t family ] (const struct sockaddr* addr,
                                                                           const uint8_t* prefix,
                                                                           unsigned int prefix_length_bits) { return FALSE; }
}
