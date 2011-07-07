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

#include <netinet/in.h>
#include "RealTimeClock.h"

/** Trivial implementation of UDP time protocol (RFC868)
 *
 * @author Peter A. Bigot
 */
module Udp6TimeP {
  provides {
    interface Init;
  }
  uses {
    interface IpSocket;
    interface IpDatagramSocket as UdpDatagramSocket;
    interface RealTimeClock;
    interface Rfc868;
  }
} implementation {

  enum {
    RDATE_PORT = 37,
  };
  
  /** Address and port for this node's service */
  typedef union sockaddr_u {
    struct sockaddr sa;
    struct sockaddr_in6 s6;
  } sockaddr_u;

  struct sockaddr_in6 serverAddress_;

  struct tm now__;
  socklen_t clientAddressLength__;
  sockaddr_u clientAddress;

  command error_t Init.init ()
  {
    serverAddress_.sin6_family = AF_INET6;
    serverAddress_.sin6_port = htons(RDATE_PORT);
    return call IpSocket.bind((struct sockaddr*)&serverAddress_);
  }

  task void transmitTime_task ()
  {
    socklen_t address_length;
    uint32_t time_rfc868;
    atomic {
      address_length = clientAddressLength__;
      time_rfc868 = call Rfc868.fromTime(&now__);
    }
    if (0 < address_length) {
      error_t rc;
      int tries = 10;
      uint32_t time_rfc868_n = htonl(time_rfc868);
      
      do {
        rc = call UdpDatagramSocket.sendto(&time_rfc868_n, sizeof(time_rfc868_n), 0, (struct sockaddr*)&clientAddress.sa, address_length);
      } while ((SUCCESS != rc) && (0 < --tries));

      atomic clientAddressLength__ = 0;
    }
  }

  async event void RealTimeClock.currentTime (const struct tm* timep,
                                              unsigned int reason_set)
  {
    if (0 != clientAddressLength__) {
      now__ = *timep;
      post transmitTime_task();
    }
  }

  event void UdpDatagramSocket.recvfrom (const void* buffer,
                                         size_t length,
                                         int flags,
                                         const struct sockaddr* address,
                                         socklen_t address_len)
  {
    bool need_response;
    atomic {
      need_response = (0 == clientAddressLength__);
      if (need_response) {
        clientAddressLength__ = address_len;
      }
    }
    if (need_response) {
      memcpy(&clientAddress.sa, address, address_len);
      call RealTimeClock.requestTime(0);
    }
  }
}
