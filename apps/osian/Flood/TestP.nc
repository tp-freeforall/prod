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

#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <net/osian.h>

module TestP {
  uses {
    interface Boot;
    interface LocalTime<TMilli> as LocalTime_bms;
    interface Button as ActiveButton;
    interface Button as InterPacketIntervalButton;
    interface Button as PacketLengthButton;
    interface Button as StatusButton;
    interface Led as ActiveLed;
    interface Led as TxToggleLed;
    interface Led as TxErrorLed;
    interface Alarm<TMilli, uint32_t> as NextPacketAlarm_bms;
    interface DeviceIdentity;
    interface NetworkInterface;
    interface IpSocket as UdpSocket;
    interface IpDatagramSocket as UdpDatagramSocket;
    interface SplitControl as RadioNicControl;
  }
} implementation {

  enum {
    Flood_port = 50124U,
  };

  /** Address and port for this node's service */
  typedef union {
    struct sockaddr sa;
    struct sockaddr_in6 s6;
  } sockaddr_u;

#ifndef IN6ADDR_TARGET_INIT
/* Initializer for target of transmitted packets.  If undefined,
 * will be set to fe80::fd41:4242:e88:2, which is the standard
 * host IP address for an OSIAN PPP link. */
#define IN6ADDR_TARGET_INIT {{{0xfe, 0x80, 0x00, 0x00, \
	 		       0x00, 0x00, 0x00, 0x00, \
	 		       0xfd, 0x41, 0x42, 0x42, \
	 		       0x0e, 0x88, 0x00, 0x02 }}}
#endif /* IN6ADDR_TARGET_INIT */

  const struct in6_addr targetAddress6 = IN6ADDR_TARGET_INIT;

  sockaddr_u myAddress;
  sockaddr_u targetAddress;

#ifndef MAX_INTER_PACKET_INTERVAL_EXPONENT
#define MAX_INTER_PACKET_INTERVAL_EXPONENT 15
#endif /* MAX_INTER_PACKET_INTERVAL_EXPONENT */
#ifndef INITIAL_INTER_PACKET_INTERVAL_EXPONENT
#define INITIAL_INTER_PACKET_INTERVAL_EXPONENT 10
#endif /* INITIAL_INTER_PACKET_INTERVAL_EXPONENT */

  /* Packet transmissions occur at intervals of
   * 2^interPacketIntervalExponent_ binary milliseconds. */
  uint8_t interPacketIntervalExponent = INITIAL_INTER_PACKET_INTERVAL_EXPONENT;
  uint32_t interPacketInterval_bms;

#ifndef MAX_RETRIES
#define MAX_RETRIES 5
#endif /* MAX_RETRIES */

  uint32_t transmitAttempts;
  uint32_t transmitSuccesses;
  uint32_t consecutiveFailures;
  error_t lastTransmitStatus;
  error_t lastFailedTransmitStatus;

#ifndef MAX_USER_PACKET_LENGTH
/* Maximum length of user data packet we're prepared to accommodate.
 * Note that this may be more than the radio will actually accept.
 * Also note that link-layer (9), IP (40), and UDP (8) headers are
 * added on top of this length. */
#define MAX_USER_PACKET_LENGTH 256
#endif /* MAX_USER_PACKET_LENGTH */

  typedef struct userData_t {
    uint32_t localTime_bms;
    uint32_t transmitAttempts;
    uint32_t transmitSuccesses;
    uint16_t retryCount;
  } userData_t;
  union {
    uint8_t buffer[256];
    userData_t structure;
  } userData_un;

  uint8_t * const userDataBuffer = userData_un.buffer;
  userData_t * const userDatap = &userData_un.structure;

  /* Valid options for the padded length of the transmitted packet.
   * It is the developer's responsibility to ensure no entry exceeds
   * MAX_USER_PACKET_LENGTH */
  const uint8_t packetLengthOptions[] = { 16, 24, 32, 48, 64, 96, 128, 160, 192 };
  uint8_t packetLengthIndex = 0;
  unsigned int packetLength;

  unsigned int rxCount;
  unsigned long int rxTotal;

  bool active;

  void displayStatus ()
  {
    uint32_t uptime_bms = call LocalTime_bms.get();
    oip_nic_state_t nic_state = call NetworkInterface.getInterfaceState();
    
    printf("\r\nUptime: %lu.%03u sec\r\n", (uptime_bms / 1024), (uint16_t)((uptime_bms % 1024) * 1000 / 1024));
    printf("Server: %s port %u\r\n", 
	     getnameinfo(&targetAddress.sa),
	     ntohs(targetAddress.s6.sin6_port));
    if (nic_state & IFF_UP) {
      printf("IP Address: %s\r\nIP port: %u\r\n",
	     getnameinfo(&myAddress.sa),
	     ntohs(myAddress.s6.sin6_port));
    } else {
      printf("Rf1aNIC down\r\n");
    }
    printf("Transmission: %s\r\n", active ? "active" : "inhibited");
    printf("Inter-packet interval: %lu bms\r\n", interPacketInterval_bms);
    printf("User packet length: %u octets\r\n", packetLength);
    printf("Attempts: %lu\r\nSuccesses (Failures): %lu (%lu)\r\n", transmitAttempts, transmitSuccesses, transmitAttempts - transmitSuccesses);
    if (0 < consecutiveFailures) {
      printf("Consecutive failures: %lu\r\n", consecutiveFailures);
    }
    printf("Last status: %d\r\nLast failure status: %d\r\n", lastTransmitStatus, lastFailedTransmitStatus);
    printf("RX: %lu bytes in %u packets\n", rxTotal, rxCount);
  }

  task void statusButton_task () { displayStatus(); }
  async event void StatusButton.pressed () { post statusButton_task(); }
  async event void StatusButton.released () { }

  void initializeInterPacketInterval ()
  {
    interPacketInterval_bms = 1UL << interPacketIntervalExponent;
  }
  task void interPacketIntervalButton_task ()
  {
    if (MAX_INTER_PACKET_INTERVAL_EXPONENT < ++interPacketIntervalExponent) {
      interPacketIntervalExponent = 0;
    }
    initializeInterPacketInterval();
    printf("Inter-packet interval set to %lu bms\r\n", interPacketInterval_bms);
  }
  async event void InterPacketIntervalButton.pressed () { post interPacketIntervalButton_task(); }
  async event void InterPacketIntervalButton.released () { }

  void initializeDataPacket ()
  {
    int i;

    packetLength = packetLengthOptions[packetLengthIndex];
    for (i = 0; i < packetLength; ++i) {
      userDataBuffer[i] = i;
    }
  }

  task void packetLengthButton_task ()
  {
    static const unsigned int MaxPacketLengthIndex = -1 + sizeof(packetLengthOptions) / sizeof(*packetLengthOptions);

    if (MaxPacketLengthIndex < ++packetLengthIndex) {
      packetLengthIndex = 0;
    }
    initializeDataPacket();
    printf("User data packets to be padded to %u octets\r\n", packetLength);
  }
  async event void PacketLengthButton.pressed () { post packetLengthButton_task(); }
  async event void PacketLengthButton.released () { }

  uint16_t lastMask = 0;
  task void nextPacketAlarm_task ()
  {
    error_t rc;
    
    if (! active) {
      return;
    }
    userDatap->transmitAttempts = transmitAttempts;
    userDatap->transmitSuccesses = transmitSuccesses;
    userDatap->retryCount = 0;
    do {
      ++userDatap->retryCount;
      userDatap->localTime_bms = call LocalTime_bms.get();
      rc = call UdpDatagramSocket.sendto(userDataBuffer, packetLength, 0, &targetAddress.sa, sizeof(targetAddress.s6));
    } while ((ERETRY != rc) && (MAX_RETRIES < userDatap->retryCount));
    ++transmitAttempts;
    lastTransmitStatus = rc;
    if (SUCCESS == rc) {
      call TxErrorLed.off();
      call TxToggleLed.toggle();
      lastMask = 0x80;
      if (consecutiveFailures > lastMask) {
	printf("Transmission succeeded\n");
      }
      consecutiveFailures = 0;
      ++transmitSuccesses;
    } else {
      call TxErrorLed.on();
      ++consecutiveFailures;
      if (0 == (consecutiveFailures & (lastMask - 1))) {
	printf("%lu sends resulted in %d\n", consecutiveFailures, rc);
	lastMask = lastMask << 1;
      }
      lastFailedTransmitStatus = rc;
    }
    call NextPacketAlarm_bms.start(interPacketInterval_bms);
  }
  async event void NextPacketAlarm_bms.fired () { post nextPacketAlarm_task(); }

  void setActive (bool active_)
  {
    active = active_;
    call ActiveLed.set(active);
    if (active) {
      printf("Transmission enabled\r\n");
      call NextPacketAlarm_bms.start(0);
    } else {
      call NextPacketAlarm_bms.stop();
      printf("Transmission inhibited\r\n");
    }
  }
  task void activeButton_task () { setActive(! active); }
  async event void ActiveButton.pressed () { post activeButton_task(); }
  async event void ActiveButton.released () { }

  event void RadioNicControl.startDone (error_t rc)
  {
    uint8_t link_local_prefix[] = { 0xfe, 0x80 };
    const struct sockaddr* llap = 0;
    bool is_multicast = IN6_IS_ADDR_MULTICAST(&targetAddress.s6.sin6_addr);

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
      sockaddr_u bind_address;
      
      memcpy(&myAddress.sa, llap, sizeof(myAddress.s6));
      myAddress.s6.sin6_port = htons(Flood_port);
      myAddress.s6.sin6_scope_id = call NetworkInterface.id();
      bind_address = myAddress;
      if (is_multicast) {
	memset(&bind_address.s6.sin6_addr, 0, sizeof(bind_address.s6.sin6_addr));
      }
      rc = call UdpSocket.bind(&bind_address.sa);
      printf("Bind to %s.%u got %d\r\n", getnameinfo(&bind_address.sa), ntohs(bind_address.s6.sin6_port), rc);
    }
    if ((SUCCESS == rc) && is_multicast) {
      int ifindex = call NetworkInterface.id();
      rc = call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_MULTICAST_IF, &ifindex, sizeof(ifindex));
      printf("MulticastIF to %d got %d\r\n", ifindex, rc);
      if (SUCCESS == rc) {
	rc = call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_JOIN_GROUP, &targetAddress.sa, sizeof(targetAddress.s6));
	printf("Join to %s got %d\r\n", getnameinfo(&targetAddress.sa), rc);
      }
    }
    if (SUCCESS == rc) {
      rc = call UdpSocket.connect(&targetAddress.sa);
      printf("Connect to %s.%u got %d\r\n", getnameinfo(&targetAddress.sa), ntohs(targetAddress.s6.sin6_port), rc);
    }
    setActive(SUCCESS == rc);
  }

  event void RadioNicControl.stopDone (error_t error) { }

  event void NetworkInterface.interfaceState (oip_nic_state_t state) { }

  event void UdpDatagramSocket.recvfrom (const void* buffer,
					 size_t length,
					 int flags,
					 const struct sockaddr* address,
					 socklen_t address_len)
  {
    // printf("RX %u from %s\n", length, getnameinfo(address));
    ++rxCount;
    rxTotal += length;
  }

  event void Boot.booted ()
  {
    error_t rc;
    
    initializeInterPacketInterval();
    initializeDataPacket();

    call ActiveButton.enable();
    call StatusButton.enable();
    call InterPacketIntervalButton.enable();
    call PacketLengthButton.enable();

    targetAddress.s6.sin6_family = AF_INET6;
    targetAddress.s6.sin6_addr = targetAddress6;
    targetAddress.s6.sin6_scope_id = call NetworkInterface.id();
    targetAddress.s6.sin6_port = htons(Flood_port);

    rc = call RadioNicControl.start();
    displayStatus();
  }
}
