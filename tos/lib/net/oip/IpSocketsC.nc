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

/** Central clearing point for all sockets in the application.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
configuration IpSocketsC {
  provides {
    interface IpSocketEntry;
    interface IpSocket[ uint8_t socket_id ];
    interface IpSocketMsg[ uint8_t socket_id ];
    interface IpDatagramSocket[ uint8_t socket_id ];
    interface IpConnectedSocket[ uint8_t socket_id ];
#if TEST_IPSOCKETS
    interface WhiteboxIpSockets;
#endif
  }
  uses {
    interface IpSocket_[ uint8_t socket_id ];
    interface IpProtocol[ uint8_t protocol ];
    interface SocketLevelOptions[ int socket_level ];
  }
} implementation {
  components IpSocketsP;
  IpSocketEntry = IpSocketsP;
  IpSocket = IpSocketsP;
  IpSocketMsg = IpSocketsP;
  IpDatagramSocket = IpSocketsP;
  IpConnectedSocket = IpSocketsP;
  IpSocket_ = IpSocketsP;
  IpProtocol = IpSocketsP;
  SocketLevelOptions = IpSocketsP;
#if TEST_IPSOCKETS
  WhiteboxIpSockets = IpSocketsP;
#endif

  IpSocketsP.SocketLevelOptions[SOL_SOCKET] -> IpSocketsP.SloSocket;

  components Icmp6C;
  IpSocketsP.Icmp6 -> Icmp6C;

  components AddressFamiliesC;
  IpSocketsP.AddressFamilies -> AddressFamiliesC;

  components NetworkInterfacesC;
  IpSocketsP.NetworkInterface -> NetworkInterfacesC;
}
