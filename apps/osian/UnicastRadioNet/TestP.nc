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
#include "IeeeEui64.h"

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
    UnicastRadioNet_port = 49152U + 1234,

    /** Number of times to retry send when clear-channel assessment fails */
    TxRetryLimit = 4,

    /** Base delay between transmissions */
    TxInterval_bms = 3 * 1024,

    /** Maximum random variance in transmission interval.  This avoids
     * problems when all boards transmit synchronously, causing
     * repeated CCA failures. */
    TxIntervalVariance_bms = 1024,

    /** Maximum number of neighbors for which we track reception
     * history. */
    MaxNeighbors = 8,
  };

  typedef struct neighbor_t {
    struct sockaddr_storage addr;
    ieee_eui64_t eui64;
    uint16_t rx_count;
    uint16_t last_seqno;
    uint32_t last_heard;
  } neighbor_t;

  neighbor_t neighbors[MaxNeighbors];

  typedef struct payload_t {
    ieee_eui64_t eui64;
    uint16_t seqno;
  } payload_t;

  payload_t payload_;

  /** List of the IIDs (modified EUI-64) values for nodes expected to
   * be present on the local radio link. */
  ieee_eui64_t known_iid [] = {
#include "known_iids.h"
    { { 0 } }
  };

  /** Pointer to the next element of known_iid to which a transmission
   * should be sent */
  ieee_eui64_t* next_iid;

  typedef union sockaddr_u {
    struct sockaddr sa;
    struct sockaddr_in6 s6;
  } sockaddr_u;

  /** Socket for destination of transmission */
  sockaddr_u your_address;

  /** Address and port for this node's service */
  sockaddr_u my_address;

  task void sendUnicastRadioNet_task ()
  {
    uint16_t interval_bms;

    if (IFF_UP & call NetworkInterface.getInterfaceState()) {
      error_t rc;
      int retries;

      /* Configure your_address to contain the address of the
       * destination node. */
      memcpy(&your_address, &my_address, sizeof(my_address));
      while (1) {
        if (0 == next_iid->data[0]) {
          int nc = 0;
          neighbor_t* np = neighbors;
          uint32_t now = call LocalTime_ms.get();
          
          ++payload_.seqno;
          printf("\r\nStatus at loop %d:\r\n", payload_.seqno);
          while ((nc < MaxNeighbors) && (np->last_heard)) {
            printf("%s rx %d, seqno %d, heard %lu ms ago\r\n",
                   getnameinfo((const struct sockaddr*)&np->addr),
                   np->rx_count, np->last_seqno, now - np->last_heard);
            ++np;
          }
          next_iid = known_iid;
          continue;
        }
        if (0 == memcmp(next_iid->data, my_address.s6.sin6_addr.s6_addr + 8, 8)) {
          ++next_iid;
          continue;
        }
        break;
      }
      memcpy(your_address.s6.sin6_addr.s6_addr + 8, next_iid->data, 8);
      ++next_iid;
      
      /* The UDP send will fail with ERETRY if clear channel
       * assessment fails.  Retry a few times in that case. */
      retries = TxRetryLimit;
      rc = ERETRY;
      while ((ERETRY == rc) && (0 < retries--)) {
        rc = call UdpDatagramSocket.sendto(&payload_, sizeof(payload_), 0, &your_address.sa, sizeof(your_address.s6));
      }
      if (SUCCESS != rc) {
        printf("Send to %s got %d after %d tries\r\n", getnameinfo(&your_address.sa), rc, TxRetryLimit - retries);
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
    post sendUnicastRadioNet_task();
  }

  event void NetworkInterface.interfaceState (oip_nic_state_t state)
  {
    printf("NIC state: %04x\r\n", state);
  }

  event void UdpDatagramSocket.recvfrom (const void* buffer,
                                         size_t length,
                                         int flags,
                                         const struct sockaddr* address,
                                         socklen_t address_len)
  {
    const payload_t* rx_payload;
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
    uint8_t link_local_prefix[] = { 0xfe, 0x80 };
    const struct sockaddr* llap;

    printf("RadioNicControl.startDone %d\r\n", rc);

    if (SUCCESS == rc) {
      /* Find the link-local address of the interface.  Such an address
       * should have been automatically configured when the link came up.
       * Then use that address to bind the socket we work with. */
      llap = call NetworkInterface.locatePrefixBinding(AF_INET6, link_local_prefix, 10);
      
      if (0 == llap) {
        printf("ERROR: No link-local address assigned\r\n");
        rc = FAIL;
      }
    }
    if (SUCCESS == rc) {
      memcpy(&my_address.sa, llap, sizeof(my_address.s6));
      my_address.s6.sin6_port = htons(UnicastRadioNet_port);
      rc = call UdpSocket.bind(&my_address.sa);
      printf("Bind to %s.%u got %d\r\n", getnameinfo(&my_address.sa), ntohs(my_address.s6.sin6_port), rc);
    }

    if (SUCCESS == rc) {
      const uint8_t *sp = my_address.s6.sin6_addr.s6_addr + 8;
      const uint8_t *esp = sp + 8;
      printf("Known IID entry for this board:\r\n\t{ {");
      while (sp < esp) {
        printf(" 0x%02x,", *sp++);
      }
      printf(" } }, // serial #\r\n");
      post sendUnicastRadioNet_task();
    }
  }

  event void RadioNicControl.stopDone (error_t error)
  {
    printf("Nic stopDone %d\r\n", error);
  }

  event void Boot.booted()
  {
    error_t rc;

    memcpy(&payload_.eui64, call DeviceIdentity.getEui64(), sizeof(payload_.eui64));
    next_iid = known_iid;
    rc = call RadioNicControl.start();
    printf("Radio start returned %d\r\n", rc);
  }
}
