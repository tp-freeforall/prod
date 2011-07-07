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

#include <net/osian.h>

/** Test infrastructure to identify the largest payload size that can
 * be successfully exchanged using both unicast and multicast
 * destination addresses.
 *
 * Use the tdl extra to set the underlying TOSH_DATA_LENGTH size,
 * which affects certain internal buffers.  Suggested: tdl,255
 *
 * Use the oipll extra to select a link layer implementation.
 * Suggested: oipll,barerf1a
 *
 * Program the same image on two boards, cat the console of each, then
 * press button 0 on either one.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
configuration TestAppC {
} implementation {
  components TestP;
  components MainC;

  TestP.Boot -> MainC;
  
  components OdiRandomC;
  TestP.Random -> OdiRandomC;

  components PlatformButtonsC;
  TestP.InitiateButton -> PlatformButtonsC.Button0;

  components new MuxAlarmMilli16C() as RepetitionAlarmC;
  TestP.RepetitionAlarm_bms -> RepetitionAlarmC;

  components new Udp6SocketC();
  TestP.UdpSocket -> Udp6SocketC;
  TestP.UdpDatagramSocket -> Udp6SocketC;

#if OIP_LINK_LAYER_IEEE154 == OIP_LINK_LAYER
  /* Automatically configure a link-local address in the PAN of the
   * Ieee154 subnet using the low 16 bits of the modified EUI-64.  Not
   * guaranteed to work, but somewhat likely; "guaranteed" would
   * require that TinyOS's Ieee154 infrastructure support LL64 instead
   * of just LL16. */
  components new Ieee154OdiAddressC(OSIAN_ULA_SUBNET_IEEE154);
  MainC.SoftwareInit -> Ieee154OdiAddressC;
#endif

  components OipLinkLayerC;
  TestP.RadioNicControl -> OipLinkLayerC;
  TestP.NetworkInterface -> OipLinkLayerC;

  components LedC;
  TestP.RxLed -> LedC.Red;
  TestP.TestingLed -> LedC.Blue;

  components SerialPrintfC;
}
