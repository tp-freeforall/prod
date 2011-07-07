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
#include <netinet/in.h>

/** Provides the IPv6 infrastructure linked into the OSIAN IP stack.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
configuration Ipv6C {
  provides {
    interface AddressFamily;
    interface IpEntry;
  }
  uses {
    interface Ipv6Header[ uint8_t protocol ];
  }
} implementation {
  components Ipv6P;
  AddressFamily = Ipv6P;
  IpEntry = Ipv6P;
  Ipv6Header = Ipv6P;

  components MainC;
  MainC.SoftwareInit -> Ipv6P;

  /* Give the component access to the network interfaces in the
   * application */
  components NetworkInterfacesC;
  Ipv6P.NetworkInterface -> NetworkInterfacesC;

  /* Hook in socket options */
  components IpSocketsC;
  IpSocketsC.SocketLevelOptions[IPPROTO_IPV6] -> Ipv6P.SloIpv6;

  /* All IPv6 implementations must provide basic ICMP */
  components Icmp6C;
  Ipv6P.Icmp6 -> Icmp6C;

  components AddressFamiliesC;
  AddressFamiliesC.AddressFamilyImpl[AF_INET6] -> Ipv6P;
  Ipv6P.AddressFamilies -> AddressFamiliesC;

}
