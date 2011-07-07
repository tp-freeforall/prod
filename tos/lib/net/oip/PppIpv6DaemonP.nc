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

module PppIpv6DaemonP {
  provides {
    interface Init;
    interface NetworkLinkInterface;
    interface NetworkInterfaceIdentifier as LocalIid;
    interface NetworkInterfaceIdentifier as RemoteIid;
  }
  uses {
    interface PppIpv6;
    interface LcpAutomaton as Ipv6LcpAutomaton;
    interface IpEntry;
    interface NetworkInterface;
  }
} implementation {

  event void Ipv6LcpAutomaton.transitionCompleted (LcpAutomatonState_e state) { }
  event void Ipv6LcpAutomaton.thisLayerUp () { }
  event void Ipv6LcpAutomaton.thisLayerDown () { }
  event void Ipv6LcpAutomaton.thisLayerStarted () { }
  event void Ipv6LcpAutomaton.thisLayerFinished () { }

  command error_t Init.init ()
  {
    /* Automatically start IPv6 when the link comes up */
    call NetworkInterface.setInterfaceState(IFF_POINTTOPOINT | call NetworkInterface.getInterfaceState());
    return call Ipv6LcpAutomaton.open();
  }

  command const uint8_t* LocalIid.interfaceIdentifier ()
  {
    return (const uint8_t*)call PppIpv6.localIid();
  }

  command uint8_t LocalIid.interfaceIdentifierLength_bits () { return 64; }
  
  command const uint8_t* RemoteIid.interfaceIdentifier ()
  {
    return (const uint8_t*)call PppIpv6.remoteIid();
  }
  command uint8_t RemoteIid.interfaceIdentifierLength_bits () { return 64; }

  event void PppIpv6.linkUp ()
  {
    uint8_t link_local_prefix[] = { 0xfe, 0x80 };

    /* Inform the interface.  This sets the link-local address which
     * we'll re-use as the link layer address. */
    call NetworkInterface.setInterfaceState(IFF_UP | call NetworkInterface.getInterfaceState());

    /* Set the link layer address to the link local address.  The only
     * reason is to enable display of the link address of the nic in
     * debugging messages. */
    call NetworkInterface.setLinkAddress(call NetworkInterface.locatePrefixBinding(AF_INET6, link_local_prefix, 10));
  }

  event error_t PppIpv6.receive (const uint8_t* message,
                                 unsigned int len)
  {
    return call IpEntry.deliver(call NetworkInterface.id(), 0, message, len);
  }

  event void NetworkInterface.interfaceState (oip_nic_state_t state) { }

  event void PppIpv6.linkDown ()
  {
    call NetworkInterface.setInterfaceState((~ IFF_UP) & call NetworkInterface.getInterfaceState());
    call NetworkInterface.setLinkAddress(0);
  }

  command int NetworkLinkInterface.storeLinkHeader (const struct sockaddr* saddr,
                                                    const struct sockaddr* daddr,
                                                    unsigned int len,
                                                    uint8_t* dst)
  {
    return 0;
  }

  command error_t NetworkLinkInterface.transmit (const void* message,
                                                 unsigned int len)
  {
    return call PppIpv6.transmit(message, len);
  }

}
