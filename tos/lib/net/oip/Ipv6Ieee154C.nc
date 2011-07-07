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

/** A network interface to the OSIAN IP stack that uses the "standard"
 * TinyOS Ieee154MessageC component for the link layer.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
configuration Ipv6Ieee154C {
  provides {
    interface NetworkInterface;
    interface SplitControl;
  }
} implementation {
  components Ipv6Ieee154P;
  SplitControl = Ipv6Ieee154P;

  components Ieee154MessageC;
  Ipv6Ieee154P.RadioControl -> Ieee154MessageC;
  Ipv6Ieee154P.Packet -> Ieee154MessageC;
  Ipv6Ieee154P.Ieee154Packet -> Ieee154MessageC;
  Ipv6Ieee154P.Ieee154Send -> Ieee154MessageC;
  Ipv6Ieee154P.Ieee154Receive -> Ieee154MessageC;
  Ipv6Ieee154P.MessageRssi -> Ieee154MessageC;
  Ipv6Ieee154P.MessageLqi -> Ieee154MessageC;

  components Ipv6C;
  Ipv6Ieee154P.IpEntry -> Ipv6C;

  components new NetworkInterfaceC();
  NetworkInterface = NetworkInterfaceC;
  NetworkInterfaceC.NetworkLinkInterface -> Ipv6Ieee154P;
  Ipv6Ieee154P.NetworkInterface -> NetworkInterfaceC;

  components DeviceModifiedEui64C;
  NetworkInterfaceC.NetworkInterfaceIdentifier -> DeviceModifiedEui64C;

}
