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
#include "IeeeEui64.h"
#include "Ipv6RadioLinkLayer.h"

#ifndef FAST_MULTICAST
/* With this flag, the configuration is changed to multicast on
 * average every 175 milliseconds, with a corresponding decrease in
 * summary frequency.  This is a stress-test for radio processing. */
#define FAST_MULTICAST 0
#endif /* FAST_MULTICAST */


module TestP {
  uses {
    interface Boot;
    interface NetworkInterface;
    interface IpSocket as UdpSocket;
    interface IpDatagramSocket as UdpDatagramSocket;
    interface SplitControl as RadioNicControl;
    interface Alarm<TMilli, uint16_t> as IntervalAlarm_bms;
    interface Random;
    interface Led as TxLed;
    interface Led as TxErrorLed;
    interface Led as RxLed;
    interface DeviceIdentity;
    interface LocalTime<TMilli> as LocalTime_ms;
  }
} implementation {

  enum {
    /** Dynamic ports are 49152 through 65535.  Pick one for this
     * application. */
    MulticastRadioNet_port = 49152U + 1234,

    /** Number of times to retry send when clear-channel assessment fails */
    TxRetryLimit = 20,

    /** Maximum number of neighbors for which we track reception
     * history. */
    MaxNeighbors = 8,

#if FAST_MULTICAST
    /** Base delay between transmissions */
    TxInterval_bms = 150,

    /** Maximum random variance in transmission interval.  This avoids
     * problems when all boards transmit synchronously, causing
     * repeated CCA failures. */
    TxIntervalVariance_bms = 50,

    /** The periodic summary of the system is printed after this many
     * iterations. */
    SummaryInterval = 100,

    /** If any neighbor stops talking for this many binary
     * milliseconds, a special summary notice is emitted.  A second
     * special summary is subsequently emitted when all known
     * neighbors have been heard within this threshold. */
    LateThreshold_bms = 20 * 1024,

    /** A special summary notice is emitted if the number of
     * consecutive failures to transmit a message reaches this level.
     * Once a message is successfully transmitted, a follow-up summary
     * is emitted. */
    WarnUnsentThreshold = 10,
#else /* FAST_MULTICAST */
    TxInterval_bms = 1024,
    TxIntervalVariance_bms = 256,
    SummaryInterval = 1,
    LateThreshold_bms = 20 * TxInterval_bms,
    WarnUnsentThreshold = 3,
#endif /* FAST_MULTICAST */
  };

  typedef struct neighbor_t {
    struct sockaddr_storage addr;
    ieee_eui64_t eui64;
    uint16_t rx_count;
    uint16_t sum_rx_count;
    uint16_t last_seqno;
    uint16_t sum_last_seqno;
    uint32_t last_heard;
  } neighbor_t;

  uint16_t myId_;
  neighbor_t neighbors[MaxNeighbors];

  typedef struct payload_t {
    ieee_eui64_t eui64;
    uint16_t seqno;
  } payload_t;

  payload_t payload_;

  /** Socket for destination of transmission */
  struct sockaddr_in6 multicastAddress_;

  /** Address and port for this node's service */
  union {
    struct sockaddr sa;
    struct sockaddr_in6 s6;
  } myAddress_;

  bool is_late;
  uint16_t num_unsent;
  uint16_t tx_failures;
  uint16_t last_seqno;
  uint16_t last_tx_failures;
  uint32_t last_rx_count;
  uint32_t last_summary_bms;

  task void sendMulticastRadioNet_task ()
  {
    uint16_t interval_bms;

    if (IFF_UP & call NetworkInterface.getInterfaceState()) {
      error_t rc;
      int retries;
      int nc = 0;
      neighbor_t* np = neighbors;
      bool do_summary;
      uint32_t now = call LocalTime_ms.get();
      uint32_t max_late = 0;

      while ((nc < MaxNeighbors) && np->last_heard) {
        uint32_t late = now - np->last_heard;
        if (late > max_late) {
          max_late = late;
        }
        ++np;
      }
      
      ++payload_.seqno;
      do_summary = (0 == (payload_.seqno % SummaryInterval));
      if (max_late < LateThreshold_bms) {
        if (is_late) {
          do_summary = TRUE;
          is_late = FALSE;
        }
      } else {
        if (! is_late) {
          do_summary = TRUE;
          is_late = TRUE;
        }
      }

      if (do_summary) {
        uint32_t rx_count = 0;
        uint16_t tx_count;
        uint16_t tx_failed;
        nc = 0;
        np = neighbors;

        tx_count = payload_.seqno - last_seqno;
        printf("\r\n%04x %u.%03u: status at loop %u (%u since last):\r\n",
               myId_,
               (uint16_t)(now >> 10),
               (uint16_t)(now & 0x3FF),
               payload_.seqno, tx_count);
        while ((nc < MaxNeighbors) && (np->last_heard)) {
          rx_count += np->rx_count;
          printf("%s rx %u [%u], seqno %u [%u], age %lu\r\n",
                 getnameinfo((const struct sockaddr*)&np->addr),
                 np->rx_count, np->rx_count - np->sum_rx_count,
                 np->last_seqno, np->last_seqno - np->sum_last_seqno,
                 now - np->last_heard);
          np->sum_rx_count = np->rx_count;
          np->sum_last_seqno = np->last_seqno;
          ++np;
        }
        tx_failed = tx_failures - last_tx_failures;
        printf("%lu bms/iter ; RX %u ; TX %u good %u fail\r\n",
               ((now - last_summary_bms) / tx_count),
               (uint16_t)(rx_count - last_rx_count),
               (tx_count - tx_failed), tx_failed);
        if (WarnUnsentThreshold < num_unsent) {
          printf("%u current consecutive failures\r\n", num_unsent);
        }
        last_summary_bms = now;
        last_seqno = payload_.seqno;
        last_rx_count = rx_count;
        last_tx_failures = tx_failures;
      }
      
      /* The UDP send will fail with ERETRY if clear channel
       * assessment fails.  Retry a few times in that case. */
      retries = TxRetryLimit;
      rc = ERETRY;
      while ((ERETRY == rc) && (0 < retries--)) {
        rc = call UdpDatagramSocket.sendto(&payload_, sizeof(payload_), 0, (struct sockaddr*)&multicastAddress_, sizeof(multicastAddress_));
      }
      if (SUCCESS != rc) {
        ++tx_failures;
        ++num_unsent;
        if (WarnUnsentThreshold == num_unsent) {
          printf("WARNING: Failed to send %u times\r\n", num_unsent);
        }
        // printf("Send to %s got %d after %d tries\r\n", getnameinfo((struct sockaddr*)&multicastAddress_), rc, TxRetryLimit - retries);
      } else {
        if (WarnUnsentThreshold <= num_unsent) {
          printf("NOTICE: Sent suceeded after %u failures\r\n", num_unsent);
        }
        num_unsent = 0;
      }
      call TxLed.toggle();
      call TxErrorLed.set(SUCCESS != rc);
    }

    /* Pick the time to wake up for the next transmission */
    interval_bms = TxInterval_bms;
    interval_bms += (TxIntervalVariance_bms * (uint32_t)(call Random.rand16())) >> 16;
    //printf("Scheduled in %u bms\r\n", interval_bms);
    call IntervalAlarm_bms.start(interval_bms);
  }

  async event void IntervalAlarm_bms.fired () {
    post sendMulticastRadioNet_task();
  }

  event void NetworkInterface.interfaceState (oip_nic_state_t state) { }

  event void UdpDatagramSocket.recvfrom (const void* buffer,
                                         size_t length,
                                         int flags,
                                         const struct sockaddr* address,
                                         socklen_t address_len)
  {
    const payload_t* rx_payload;
#if ! FAST_MULTICAST
    const Ipv6RadioLinkLayerRxMetadata_t* metadata = (const Ipv6RadioLinkLayerRxMetadata_t*)call NetworkInterface.rxMetadata();
    if (metadata) {
      printf("RX %u bytes rssi %d lqi %d\r\n", length, metadata->rssi, metadata->lqi);
    }
#endif /* ! FAST_MULTICAST */

    call RxLed.toggle();
    if (sizeof(*rx_payload) == length) {
      neighbor_t* np = neighbors;
      int ni;
      rx_payload = (const payload_t*)buffer;
      for (ni = 0, np = neighbors; ni < MaxNeighbors; ++ni, ++np) {
        if (0 == np->last_heard) {
          break;
        }
        if (0 == memcmp(&np->addr, address, address_len)) {
          break;
        }
      }
      if (ni < MaxNeighbors) {
        if (0 == np->last_heard) {
          memcpy(&np->addr, address, address_len);
          memcpy(&np->eui64, &rx_payload->eui64, sizeof(np->eui64));
        }
        ++np->rx_count;
        np->last_seqno = rx_payload->seqno;
        np->last_heard = call LocalTime_ms.get();
      }
    } else {
      printf("UDP RX %u bytes from %s\r\n", length, getnameinfo(address));
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
      multicastAddress_.sin6_port = htons(MulticastRadioNet_port);
      
      rc = call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_JOIN_GROUP, &multicastAddress_, sizeof(multicastAddress_));
      printf("Join to %s got %d\r\n", getnameinfo((struct sockaddr*)&multicastAddress_), rc);
    }
    if (SUCCESS == rc) {
      memset(&myAddress_, 0, sizeof(myAddress_));
      myAddress_.s6.sin6_family = AF_INET6;
      myAddress_.s6.sin6_port = htons(MulticastRadioNet_port);
      rc = call UdpSocket.bind(&myAddress_.sa);
      printf("Bind to %s got %d\r\n", getnameinfo(&myAddress_.sa), rc);
    }
    if (SUCCESS == rc) {
      post sendMulticastRadioNet_task();
    }
  }

  event void RadioNicControl.stopDone (error_t error) { }

  event void Boot.booted()
  {
    error_t rc;
    
    memcpy(&payload_.eui64, call DeviceIdentity.getEui64(), sizeof(payload_.eui64));
    myId_ = ntohs(*(uint16_t*)(payload_.eui64.data + 6));
    rc = call RadioNicControl.start();
    printf("Radio start returned %d\r\n", rc);
  }
}
