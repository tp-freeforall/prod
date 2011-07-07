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

#include "IeeeEui64.h"
#include "Ipv6RadioLinkLayer.h"

module Ipv6BareLinkLayerP {
  uses {
    interface NetworkInterface;
    interface BareTxRx;
    interface BareMetadata;
    interface SplitControl as BareControl;
    interface IpEntry;
  }
  provides {
    interface SplitControl;
    interface NetworkLinkInterface;
  }
} implementation {
  const uint8_t* iid_;
  uint8_t iidLength_;

  Ipv6RadioLinkLayerRxMetadata_t metadata_;

  enum {
    MAGIC_HEADER = 0x96,
  };

  event void BareControl.startDone (error_t rc)
  {
    if (SUCCESS == rc) {
      call NetworkInterface.setInterfaceState(IFF_UP | call NetworkInterface.getInterfaceState());
      iid_ = call NetworkInterface.interfaceIdentifier();
      iidLength_ = call NetworkInterface.interfaceIdentifierLength_bits();
      /* OK, yuck, but almost everything should use a 64-bit IID, and I
       * don't want to have to deal with anything else. */
      if (64 != iidLength_) {
        rc = ESIZE;
      }
    }
    signal SplitControl.startDone(rc);
  }
  event void BareControl.stopDone (error_t rc)
  {
    signal SplitControl.stopDone(rc);
  }

  event void BareTxRx.sendDone (error_t rc) { }
  

  command error_t SplitControl.start () { return call BareControl.start(); }
  command error_t SplitControl.stop () {
    call NetworkInterface.setInterfaceState((~ IFF_UP) & call NetworkInterface.getInterfaceState());
    return call BareControl.stop();
  }

  event void NetworkInterface.interfaceState (oip_nic_state_t state)
  {
  }
  
  command int NetworkLinkInterface.storeLinkHeader (const struct sockaddr* saddr,
                                                    const struct sockaddr* daddr,
                                                    unsigned int len,
                                                    uint8_t* dst)
  {
    const uint8_t* sllp;
    uint8_t sll_len;
    const uint8_t* dllp;
    uint8_t dll_len = 0;
    const struct sockaddr_in6* d6p = (const struct sockaddr_in6*)daddr;

    if (d6p) {
      const struct in6_addr* i6p = &d6p->sin6_addr;
      
      if (IN6_IS_ADDR_MULTICAST(i6p)) {
        dll_len = 0;
      } else {
        dll_len = 8;
        dllp = d6p->sin6_addr.s6_addr + 8;
      }
    }
    sll_len = (iidLength_ + 7) / 8;
    sllp = iid_;

    if (dst) {
      *dst++ = MAGIC_HEADER;
      *dst++ = (sll_len << 4) | dll_len;
      if (sll_len) {
        memcpy(dst, sllp, sll_len);
        dst += sll_len;
      }
      if (dll_len) {
        memcpy(dst, dllp, dll_len);
        dst += dll_len;
      }
    }
    return 2 + sll_len + dll_len;
  }

  command error_t NetworkLinkInterface.transmit (const void* message,
                                                 unsigned int len)
  {
    return call BareTxRx.send(message, len);
  }

  void dump_iid (const uint8_t* dp,
                 int length)
  {
    while (length--) {
      printf("%02x", *dp++);
    }
  }

  event void BareTxRx.receive (const void* data,
                               unsigned int length)
  {
    const uint8_t* bp = data;
    const uint8_t* sllp = 0;
    uint8_t sll_len;
    const uint8_t* dllp = 0;
    uint8_t dll_len;
    error_t rc;

    if ((2 > length) || (MAGIC_HEADER != *bp++)) {
      return;
    }
    sll_len = 0x0F & (*bp >> 4);
    dll_len = 0x0F & *bp++;
    length -= 2;
    if (sll_len > length) {
      return;
    }
    if (0 < sll_len) {
      sllp = bp;
      bp += sll_len;
      length -= sll_len;
    }
    if (dll_len > length) {
      return;
    }
    if (0 < dll_len) {
      dllp = bp;
      bp += dll_len;
      length -= dll_len;
    }

    metadata_.rssi = call BareMetadata.rssi();
    metadata_.lqi = call BareMetadata.lqi();

#if 0
    printf("SRC ");
    dump_iid(sllp, sll_len);
    printf(" DST ");
    dump_iid(dllp, dll_len);
    printf("\n");
#endif

    if (! (IFF_PROMISC & call NetworkInterface.getInterfaceState())) {
      if (dll_len && (0 != memcmp(iid_, dllp, dll_len))) {
        return;
      }
    }

    signal NetworkLinkInterface.provideRxMetadata(&metadata_);
    rc = call IpEntry.deliver(call NetworkInterface.id(), 0, bp, length);
#if 0
    printf("Delivery got %d\n", rc);
#endif
  }
  
}
