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

/** Configure a PPP daemon with IPv6 support.
 *
 * Doing this is complex (see below); make it easy on the poor
 * developer by providing a standard component that's got what you
 * normally need, and publishes the interfaces so you can customize.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com> */
configuration PppIpv6DaemonC {
  uses {
    interface PppProtocol[ uint16_t protocol ];
    interface DisplayCode as DisplayCodeLcpState;
  }
  provides {
    interface SplitControl;
    interface LcpAutomaton as PppLcpAutomaton;
    interface LcpAutomaton as Ipv6LcpAutomaton;
    interface Ppp;
    interface NetworkInterface;
    interface NetworkInterfaceIdentifier as LocalIid;
    interface NetworkInterfaceIdentifier as RemoteIid;
  }
} implementation {

  // Initialization includes opening the IPv6 LCP
  components PppIpv6DaemonP;
  components MainC;
  MainC.SoftwareInit -> PppIpv6DaemonP;

  // Create a NIC corresponding to the PPP link
  components new NetworkInterfaceC();
  NetworkInterface = NetworkInterfaceC;
  PppIpv6DaemonP.NetworkInterface -> NetworkInterfaceC;
  PppIpv6DaemonP.NetworkLinkInterface <- NetworkInterfaceC;
  PppIpv6DaemonP.LocalIid <- NetworkInterfaceC;

  // Publish the standard PPP daemon interfaces
  components PppDaemonC;
  PppProtocol = PppDaemonC;
  SplitControl = PppDaemonC;
  PppLcpAutomaton = PppDaemonC;
  Ppp = PppDaemonC;
  DisplayCodeLcpState = PppDaemonC;

  // Hook up the generic PPP IPv6 interface
  components PppIpv6C;
  PppIpv6DaemonP.PppIpv6 -> PppIpv6C;

  // Hook up the required interface

  // Provide access to the local and remote IIDs
  LocalIid = PppIpv6DaemonP.LocalIid;
  RemoteIid = PppIpv6DaemonP.RemoteIid;

  // Provide access to the LCP automaton
  Ipv6LcpAutomaton = PppIpv6C;

  // Hook in the IPv6 protocols
  PppDaemonC.PppProtocol[PppIpv6C.ControlProtocol] -> PppIpv6C.PppControlProtocol;
  PppDaemonC.PppProtocol[PppIpv6C.Protocol] -> PppIpv6C.PppProtocol;
  PppIpv6C.Ppp -> PppDaemonC;
  PppIpv6C.LowerLcpAutomaton -> PppDaemonC;
  PppIpv6DaemonP.Ipv6LcpAutomaton -> PppIpv6C;

  // Hook in the IPv6 stack
  components Ipv6C;
  PppIpv6DaemonP.IpEntry -> Ipv6C;

  // Provide the standard serial interface over which PPP will run
  components PlatformSerialHdlcUartC;
  PppDaemonC.HdlcUart -> PlatformSerialHdlcUartC;
  PppDaemonC.UartControl -> PlatformSerialHdlcUartC;
}
