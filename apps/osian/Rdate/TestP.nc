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

#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <net/osian.h>
#include "RealTimeClock.h"

module TestP {
  uses {
    interface Boot;
    interface NetworkInterface;
    interface IpSocket as UdpSocket;
    interface IpDatagramSocket as UdpDatagramSocket;
    interface SplitControl as RadioNicControl;
    interface Alarm<TMilli, uint32_t> as IntervalAlarm_bms;
    interface Random;
    interface StdControl as RtcControl;
    interface RealTimeClock;
    interface Rfc868;
  }
} implementation {
  /** Socket for destination of transmission */
  struct sockaddr_in6 multicastAddress_;

  enum {
    USER_RDATE_PORT = 1037,
    RDATE_REQUEST_INTERVAL_bms = 5 * 1024U,
    RDATE_REQUEST_LIMIT = 10,
  };

  /** Address and port for this node's service */
  union {
    struct sockaddr sa;
    struct sockaddr_in6 s6;
  } myAddress_;

  bool haveTime__;

  typedef struct user_rdate_t {
    uint32_t time_rfc868;
    uint16_t stratum;
  } user_rdate_t;

  task void requestDate_task ()
  {
    error_t rc;
    int tries = 0;
    
    do {
      rc = call UdpDatagramSocket.sendto(0, 0, 0, (struct sockaddr*)&multicastAddress_, sizeof(multicastAddress_));
    } while ((SUCCESS != rc) && (RDATE_REQUEST_LIMIT > ++tries));
    call IntervalAlarm_bms.start(RDATE_REQUEST_INTERVAL_bms);
    printf("Date request got %d after %d tries\r\n", rc, tries);
  }

  async event void IntervalAlarm_bms.fired ()
  {
    if (! haveTime__) {
      post requestDate_task();
    }
  }

  norace struct tm timestamp_;
  task void timestamp_task ()
  {
    printf("%04d-%02d-%02dT%02d:%02d:%02dZ wday %d\r\n",
           1900 + timestamp_.tm_year, 1 + timestamp_.tm_mon, timestamp_.tm_mday,
           timestamp_.tm_hour, timestamp_.tm_min, timestamp_.tm_sec,
           timestamp_.tm_wday);
  }

  async event void RealTimeClock.currentTime (const struct tm* timep,
                                              unsigned int reason_set)
  {
    timestamp_ = *timep;
    post timestamp_task();
  }

  event void NetworkInterface.interfaceState (oip_nic_state_t state) { }
  event void UdpDatagramSocket.recvfrom (const void* buffer,
                                         size_t length,
                                         int flags,
                                         const struct sockaddr* address,
                                         socklen_t address_len)
  {
    user_rdate_t* rp = (user_rdate_t*)buffer;
    uint32_t time_rfc868;
    int stratum;

    if (sizeof(*rp) != length) {
      printf("Received unexpected %d-octet packet from %s\r\n", length, getnameinfo(address));
      return;
    }
    stratum = ntohs(rp->stratum);
    time_rfc868 = ntohl(rp->time_rfc868);
    printf("Response date %lu stratum %d from %s\r\n", time_rfc868, stratum, getnameinfo(address));
    if (0 == stratum) {
      struct tm time;
      error_t rc;

      rc = call Rfc868.toTime(time_rfc868, &time);
      if (SUCCESS == rc) {
        rc = call RtcControl.start();
      }
      if (SUCCESS == rc) {
        rc = call RealTimeClock.setTime(&time);
      }
      if (SUCCESS == rc) {
        atomic haveTime__ = 1;
        call IntervalAlarm_bms.stop();
        rc = call RealTimeClock.setIntervalMode(RTC_INTERVAL_MODE_MIN);
        printf("Set time complete, minute interval mode %d\r\n", rc);
      }
      
    }
  }

  event void RadioNicControl.startDone (error_t rc)
  {
    int ifindex;

    printf("RadioNicControl.startDone %d\r\n", rc);
    if (SUCCESS == rc) {
      ifindex = call NetworkInterface.id();
      rc = call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_MULTICAST_IF, &ifindex, sizeof(ifindex));
      printf("MulticastIF to %d got %d\r\n", ifindex, rc);
    }
    if (SUCCESS == rc) {
      multicastAddress_.sin6_family = AF_INET6;
      /* ff02::1 is site all-hosts address */
      multicastAddress_.sin6_addr.s6_addr[0] = 0xff;
      multicastAddress_.sin6_addr.s6_addr[1] = 0x02;
      multicastAddress_.sin6_addr.s6_addr[15] = 0x1;
      multicastAddress_.sin6_scope_id = ifindex;
      multicastAddress_.sin6_port = htons(USER_RDATE_PORT);
      
      rc = call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_JOIN_GROUP, &multicastAddress_, sizeof(multicastAddress_));
      printf("Join to %s got %d\r\n", getnameinfo((struct sockaddr*)&multicastAddress_), rc);
    }
    if (SUCCESS == rc) {
      memset(&myAddress_, 0, sizeof(myAddress_));
      myAddress_.s6.sin6_family = AF_INET6;
      myAddress_.s6.sin6_port = htons(USER_RDATE_PORT);
      rc = call UdpSocket.bind(&myAddress_.sa);
      printf("Bind to %s got %d\r\n", getnameinfo(&myAddress_.sa), rc);
    }
    if (SUCCESS == rc) {
      post requestDate_task();
    }
  }

  event void RadioNicControl.stopDone (error_t error) { }

  event void Boot.booted () {
    error_t rc = call RadioNicControl.start();
    printf("RFC868 Test Program started\r\n");
#if defined( __MSP430_HAS_UCS_RF__) || defined( __MSP430_HAS_UCS__)
    printf("XT1 crystal is %sabled\r\n", (UCSCTL6 & XT1OFF) ? "dis" : "en");
#endif
    printf("Radio start returned %d\r\n", rc);
  }
}
