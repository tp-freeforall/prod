/* Copyright (c) 2011 People Power Co.
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

/** The Flood application is used for high-traffic network testing.
 * It transmits UDP packets direct to a gateway node at a specified
 * rate.  The length of the packets and the rate is dynamically
 * controllable.  The transmission can be inhibited.  The application
 * can target its transmissions to either a unicast or multicast
 * address.  Each application displays status to the console, and the
 * floodmon.py application, when run with a ppp bridge to the RF1A
 * radio link, serves as the receiver for all transmitted packets.
 * 
 * Each transmitted packet contains:
 * - Time since boot in binary milliseconds
 * - Total number of transmission since boot
 *
 * In addition to its primary function, the application responds to ping and to
 * UDP echo requests.
 *
 * Controls:
 * B0 -- Toggle to enable/disable transmission of packets
 * B1 -- Press to cycle through inter-packet transmission delays
 * B2 -- Press to cycle through packet payload lengths
 * B3 -- Press to display system status
 *
 * Feedback:
 * Green -- Toggles on transmission of a packet
 * Red -- Lit if EBUSY is returned for a transmission
 * Blue -- Lit if transmission is enabled
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
configuration TestAppC {
} implementation {
  components TestP;
  components MainC;

  TestP.Boot -> MainC;
  
  components LocalTimeMilliC;
  TestP.LocalTime_bms -> LocalTimeMilliC;

  components PlatformButtonsC;
  TestP.ActiveButton -> PlatformButtonsC.Button0;
  TestP.InterPacketIntervalButton -> PlatformButtonsC.Button1;
  TestP.PacketLengthButton -> PlatformButtonsC.Button2;
  TestP.StatusButton -> PlatformButtonsC.Button3;

  components LedC;
  TestP.ActiveLed -> LedC.Blue;
  TestP.TxToggleLed -> LedC.Green;
  TestP.TxErrorLed -> LedC.Red;

  components DeviceIdentityC;
  TestP.DeviceIdentity -> DeviceIdentityC;

  components new MuxAlarmMilli32C() as NextPacketAlarmC;
  TestP.NextPacketAlarm_bms -> NextPacketAlarmC;

  components new Udp6SocketC();
  TestP.UdpSocket -> Udp6SocketC;
  TestP.UdpDatagramSocket -> Udp6SocketC;

  /* Automatically configure a link-local address in the PAN of the
   * Ieee154 subnet using the low 16 bits of the modified EUI-64.  Not
   * guaranteed to work, but somewhat likely; "guaranteed" would
   * require that TinyOS's Ieee154 infrastructure support LL64 instead
   * of just LL16. */
  components new Ieee154OdiAddressC(OSIAN_ULA_SUBNET_IEEE154);
  MainC.SoftwareInit -> Ieee154OdiAddressC;

  //components Ipv6Ieee154C as OipLinkLayerC;
  components OipLinkLayerC;
  TestP.RadioNicControl -> OipLinkLayerC;
  TestP.NetworkInterface -> OipLinkLayerC;
 
  // Add other network services
  components Icmp6EchoRequestC;
  components Udp6EchoC;
  //components Udp6TimeC;

  components SerialPrintfC;
}
