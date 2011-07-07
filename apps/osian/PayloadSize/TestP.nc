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

/* Before doing anything else, if the user didn't provide a data
 * length use the maximum we expect might work. */
#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 255
#endif /* TOSH_DATA_LENGTH */

#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <net/osian.h>
#include "OipLinkLayer.h"

module TestP {
  uses {
    interface Boot;
    interface Button as InitiateButton;
    interface Random;
    interface Alarm<TMilli, uint16_t> as RepetitionAlarm_bms;
    interface Led as RxLed;
    interface Led as TestingLed;
    interface NetworkInterface;
    interface IpSocket as UdpSocket;
    interface IpDatagramSocket as UdpDatagramSocket;
    interface SplitControl as RadioNicControl;
  }
} implementation {

#ifndef MIN_PAYLOAD_SIZE
/** The smallest payload size to test.  If this size fails, the
 * experiment is aborted. */
#define MIN_PAYLOAD_SIZE 16
#endif /* MIN_PAYLOAD_SIZE */

#ifndef MAX_PAYLOAD_SIZE
/** The largest payload size to test. */
#define MAX_PAYLOAD_SIZE 1023
#endif /* MAX_PAYLOAD_SIZE */

#ifndef REPETITIONS_PER_PAYLOAD
/** The number of times each payload size is tested.  Success in any
 * trial is considered evidence that the payload size works. */
#define REPETITIONS_PER_PAYLOAD 3
#endif /* REPETITIONS_PER_PAYLOAD */

#ifndef TRANSMISSIONS_PER_REPETITION
/** The number of times we attempt to transmit the packet for each
 * reptition.  This allows for CSMA backoff. */
#define TRANSMISSIONS_PER_REPETITION 10
#endif /* TRANSMISSIONS_PER_REPETITION */

#ifndef RESPONSE_BASE_TIMEOUT_BMS
/** Base time to wait, independent of tested payload size */
#define RESPONSE_BASE_TIMEOUT_BMS 256U
#endif /* RESPONSE_BASE_TIMEOUT_BMS */

#ifndef RESPONSE_PER_BYTE_TIMEOUT_BMS
/** Adjustment to response wait timeout, per byte in the tested payload */
#define RESPONSE_PER_BYTE_TIMEOUT_BMS 1U
#endif /* RESPONSE_PER_BYTE_TIMEOUT_BMS */
  
  enum {
    /** Dynamic ports are 49152 through 65535.  Pick one for this
     * application. */
    MulticastRadioNet_port = 49152U + 1242,
  };
 
  /** Address and port for this node's service */
  typedef union sockaddr_u{
    struct sockaddr sa;
    struct sockaddr_in6 s6;
  } sockaddr_u;

  sockaddr_u multicastAddress_;
  sockaddr_u myAddress_;

  uint8_t outgoingPayload[MAX_PAYLOAD_SIZE];
  error_t payloadResult;
  error_t repetitionResult;
  int repetitionsLeft;
  unsigned int payloadSizeBound;
  unsigned int largestPayloadSize;
  unsigned int testPayloadSize;

  void testPayload (unsigned int payload);
  void runRepetition ();

  task void completeTest_task ()
  {
    if (largestPayloadSize == payloadSizeBound) {
      printf("Completely failed to exchange packets\r\n");
    } else {
      printf("Largest successful is %u\r\n", largestPayloadSize);
      printf("Known-to-fail is %u\r\n", payloadSizeBound);
    }
    testPayloadSize = 0;
    call TestingLed.off();
    call InitiateButton.enable();
  }

  task void completeRepetition_task ()
  {
    unsigned int next_payload;

    if ((SUCCESS != payloadResult) && (0 < --repetitionsLeft)) {
      runRepetition();
      return;
    }
    if (SUCCESS == payloadResult) {
      printf("Succeeded with payload size %u\r\n", testPayloadSize);
      largestPayloadSize = testPayloadSize;
    } else {
      printf("Failed with payload size %u: code %d\r\n", testPayloadSize, payloadResult);
      payloadSizeBound = testPayloadSize;
    }
    next_payload = largestPayloadSize + ((payloadSizeBound - largestPayloadSize) / 2);
    if (largestPayloadSize == next_payload) {
      post completeTest_task();
      return;
    }
    testPayload(next_payload);
  }

  void acceptResponse ()
  {
    payloadResult = SUCCESS;
    call RepetitionAlarm_bms.stop();
    post completeRepetition_task();
  }

  async event void RepetitionAlarm_bms.fired ()
  {
    post completeRepetition_task();
  }

  void runRepetition ()
  {
    error_t rc;
    uint16_t timeout_bms = RESPONSE_BASE_TIMEOUT_BMS + testPayloadSize * RESPONSE_PER_BYTE_TIMEOUT_BMS;
    int retries = TRANSMISSIONS_PER_REPETITION;

    do {
      rc = call UdpDatagramSocket.sendto(outgoingPayload, testPayloadSize, 0, &multicastAddress_.sa, sizeof(multicastAddress_.s6));
    } while ((ERETRY == rc) && (0 < retries--));
    if ((SUCCESS == rc) || (ERETRY == rc)) {
      call RepetitionAlarm_bms.start(timeout_bms);
    } else {
      printf("Transmit failed locally with %d\r\n", rc);
      repetitionsLeft = 0;
      payloadResult = rc;
      post completeRepetition_task();
    }
  }

  void testPayload (unsigned int payload)
  {
    uint8_t* pp;
    if (payload > sizeof(outgoingPayload)) {
      repetitionsLeft = 0;
      payloadResult = ENOMEM;
      post completeRepetition_task();
      return;
    }
    payloadResult = ENOACK;
    testPayloadSize = payload;
    pp = outgoingPayload;
    *pp++ = 0;
    while (0 < --payload) {
      *pp++ = 0xff & call Random.rand16();
    }
    repetitionsLeft = REPETITIONS_PER_PAYLOAD;
    printf("Test %u (best so far %u, known-to-fail %u)\r\n", testPayloadSize, largestPayloadSize, payloadSizeBound);
    runRepetition();
  }

  void dumpLinkLayerInfo ()
  {
    printf("OIP_LINK_LAYER="
#if OIP_LINK_LAYER_IEEE154 == OIP_LINK_LAYER
	   "ieee154"
#elif OIP_LINK_LAYER_BARERF1A == OIP_LINK_LAYER
	   "bareRF1A"
#else
	   "unregistered value %u", OIP_LINK_LAYER
#endif
	   );
    printf("\r\nTOSH_DATA_LENGTH=%u\r\n", TOSH_DATA_LENGTH);
  }

  task void initiateButton_task ()
  {
    printf("Test initiated\r\n");
    dumpLinkLayerInfo();
    
    call TestingLed.on();
    largestPayloadSize = MIN_PAYLOAD_SIZE;
    payloadSizeBound = MAX_PAYLOAD_SIZE + 1;
    testPayload(largestPayloadSize);
  }

  async event void InitiateButton.pressed ()
  {
    call InitiateButton.disable();
    post initiateButton_task();
  }
  async event void InitiateButton.released () { }

  event void NetworkInterface.interfaceState (oip_nic_state_t state) { }

  event void UdpDatagramSocket.recvfrom (const void* buffer,
                                         size_t length,
                                         int flags,
                                         const struct sockaddr* address,
                                         socklen_t address_len)
  {
    const uint8_t* payload = (const uint8_t*)buffer;
    
    printf("Received 0x%02x length %u from %s, expect %u\r\n", payload[0], length, getnameinfo(address), testPayloadSize);
    if (0 == payload[0]) {
      int retries = TRANSMISSIONS_PER_REPETITION;
      error_t rc;

      memcpy(outgoingPayload, payload, length);
      outgoingPayload[0] = 1;
      do {
	rc = call UdpDatagramSocket.sendto(outgoingPayload, length, 0, address, address_len);
      } while ((ERETRY == rc) && (0 < retries--));
      printf("Echo response got %d\r\n", rc);
      return;
    }
    if ((length == testPayloadSize) &&
	(0 == memcmp(payload+1, outgoingPayload+1, length-1))) {
      acceptResponse();
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
      multicastAddress_.s6.sin6_family = AF_INET6;
      /* ff02::1 is site all-hosts address */
      multicastAddress_.s6.sin6_addr.s6_addr[0] = 0xff;
      multicastAddress_.s6.sin6_addr.s6_addr[1] = 0x02;
      multicastAddress_.s6.sin6_addr.s6_addr[15] = 0x1;
      multicastAddress_.s6.sin6_scope_id = ifindex;
      multicastAddress_.s6.sin6_port = htons(MulticastRadioNet_port);
      
      rc = call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_JOIN_GROUP, &multicastAddress_.s6, sizeof(multicastAddress_.s6));
      printf("Join to %s got %d\r\n", getnameinfo(&multicastAddress_.sa), rc);
    }
    if (SUCCESS == rc) {
      memset(&myAddress_, 0, sizeof(myAddress_));
      myAddress_.s6.sin6_family = AF_INET6;
      myAddress_.s6.sin6_port = htons(MulticastRadioNet_port);
      rc = call UdpSocket.bind(&myAddress_.sa);
      printf("Bind to %s got %d\r\n", getnameinfo(&myAddress_.sa), rc);
    }
    printf("NIC configuration got %d\r\n", rc);
    if (SUCCESS == rc) {
      call InitiateButton.enable();
    }
  }

  event void RadioNicControl.stopDone (error_t error) { }

  event void Boot.booted () {
    error_t rc;
    
    rc = call RadioNicControl.start();
    dumpLinkLayerInfo();
    printf("NIC start got %d\r\n", rc);
  }
}
