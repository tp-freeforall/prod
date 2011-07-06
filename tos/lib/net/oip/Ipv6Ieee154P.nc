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


#include "message.h"
#include <netinet/in.h>
#include <arpa/inet.h>

#include "Ipv6RadioLinkLayer.h"

module Ipv6Ieee154P {
  uses {
    interface NetworkInterface;
    interface DeviceIdentity;
    interface Packet;
    interface Ieee154Packet;
    interface Ieee154Send;
    interface Receive as Ieee154Receive;
    interface IpEntry;
    interface MessageLqi;
    interface MessageRssi;
    interface SplitControl as RadioControl;
  }
  provides {
    interface SplitControl;
    interface NetworkLinkInterface;
  }
} implementation {

  command error_t SplitControl.start () { return call RadioControl.start(); }
  event void RadioControl.startDone (error_t error)
  {
    if (SUCCESS == error) {
      call NetworkInterface.setInterfaceState(IFF_UP | call NetworkInterface.getInterfaceState());
    }
    signal SplitControl.startDone(error);
  }

  command error_t SplitControl.stop ()
  {
    call NetworkInterface.setInterfaceState((~ IFF_UP) & call NetworkInterface.getInterfaceState());
    return call RadioControl.stop();
  }
  event void RadioControl.stopDone (error_t error)
  {
    signal SplitControl.stopDone(error);
  }

  ieee154_saddr_t dest_saddr;
  struct Ipv6RadioLinkLayerRxMetadata_t metadata;

  message_t message;
  bool inUse_;

  event void NetworkInterface.interfaceState (oip_nic_state_t state) { }
  event void Ieee154Send.sendDone(message_t* msg, error_t error)
  {
    //printf("SND done %d\r\n", error);
    inUse_ = FALSE;
  }

  event message_t* Ieee154Receive.receive(message_t* msg, void* payload, uint8_t len)
  {
    error_t rc;

    //printf("RCV %d at %p payload %p\r\n", len, msg, payload);
    metadata.rssi = call MessageRssi.rssi(msg);
    metadata.lqi = call MessageLqi.lqi(msg);
    signal NetworkLinkInterface.provideRxMetadata(&metadata);
    rc = call IpEntry.deliver(call NetworkInterface.id(), 0, payload, len);
    //printf("DEL got %d\r\n", rc);
    return msg;
  }

  command int NetworkLinkInterface.storeLinkHeader (const struct sockaddr* saddr,
                                                    const struct sockaddr* daddr,
                                                    unsigned int len,
                                                    uint8_t* dst)
  {
    const struct sockaddr_in6* d6p = (const struct sockaddr_in6*)daddr;
    
    dest_saddr = IEEE154_BROADCAST_ADDR;
    if (d6p) {
      const struct in6_addr* i6p = &d6p->sin6_addr;

      //if (IN6_IS_ADDR_MULTICAST(i6p)) {  
      //Not very elegant!! but allows the node to be accessed from a remote network via the OSIAN PppBridge
      //so if a node replies to an address that is not a linklocal or sitelocal address the ieee packet is broadcast,
      //the Pppbridge will then bridge the packet and from there it can be routed back to the calling host.    
      //When routing is added to OSIAN this can be removed!!.
      if (IN6_IS_ADDR_MULTICAST(i6p) || !IN6_IS_ADDR_LINKLOCAL(i6p) || !IN6_IS_ADDR_SITELOCAL(i6p)) {
      } else {
        dest_saddr = ntohs(*(uint16_t*)(d6p->sin6_addr.s6_addr + 14));
      }
    }
    // printf("SLH at %p to %04x\r\n", dst, dest_saddr);
    return 0;
  }

  command error_t NetworkLinkInterface.transmit (const void* data,
                                                 unsigned int len)
  {
    void* dp;
    error_t rc;

    if (inUse_) {
      return EBUSY;
    }
    inUse_ = TRUE;
    call Packet.clear(&message);
    dp = call Packet.getPayload(&message, len);
    if (! dp) {
      inUse_ = FALSE;
      return ENOMEM;
    }
    memcpy(dp, data, len);
    rc = call Ieee154Send.send(dest_saddr, &message, len);
    inUse_ = (SUCCESS == rc);
    // printf("Transmit %d bytes at %p to %04x got %d\r\n", len, data, dest_saddr, rc);
    return rc;
  }

}
