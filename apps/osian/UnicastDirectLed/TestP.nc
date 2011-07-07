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

module TestP {
  uses {
    interface Boot;
    interface SplitControl as PppControl;
    interface NetworkInterface as PppNic;
    interface NetworkInterfaceIdentifier as PppRemoteIid;
    interface Alarm<TSecond, uint32_t>;
    interface MultiLed;
    interface Led as PppNicLed;
    interface IpSocket as UdpSocket;
    interface IpConnectedSocket;
    interface LocalTime<TMilli> as LocalTime_msec;
    interface Button as EventButton;
  }
  
} implementation {

  /** Struct transmitted (in native little-endian byte order) to
   * inform the monitor of an event */
  struct event_t {
    uint32_t time_msec;
    uint16_t counter;
    uint8_t event_tag;
  };

  /** Structure received (in native little-endian byte order) from
   * controller to cause a configuration change */
  struct command_t {
    uint16_t counter;
    uint8_t cmd_tag;
  };

  enum {
    CMD_Hello = 0,
    EVT_Status = 0,
    EVT_Rollover = 1,
    EVT_Button = 2,
    CMD_ResetCounter = 3,
    EVT_ResetCounter = 3,
  };

  enum {
    Interval_sec = 1,
    Counter_mask = 0x0F,
    ServicePort = 60102U,
  };
  
  struct sockaddr_in6 localAddress;
  struct sockaddr* localAddress_sap;
  struct sockaddr_in6 remoteAddress;
  struct sockaddr* remoteAddress_sap;

  uint16_t counter;

  error_t sendEvent (uint8_t event_tag)
  {
    struct event_t evt;
    evt.time_msec = call LocalTime_msec.get();
    evt.counter = counter;
    evt.event_tag = event_tag;
    return call IpConnectedSocket.send(&evt, sizeof(evt), 0);
  }

  task void periodic_task ()
  {
    uint16_t masked_counter = Counter_mask & ++counter;
    call MultiLed.set(((~ Counter_mask) & call MultiLed.get()) | masked_counter);
    if ((0 == masked_counter) && (IFF_UP & call PppNic.getInterfaceState())) {
      error_t rc = sendEvent(EVT_Rollover);
      printf("Send %u returned %d\r\n", counter, rc);
    }
    call Alarm.start(Interval_sec);
  }

  task void event_task ()
  {
    error_t rc = sendEvent(EVT_Button);
    printf("Event got %d\r\n", rc);
  }

  async event void EventButton.pressed () { post event_task(); }
  async event void EventButton.released () { }

  event void IpConnectedSocket.recv (const void* buffer,
                                     size_t length,
                                     int flags)
  {
    const struct command_t* cmdp = buffer;
    error_t rc;
    
    if (length != sizeof(*cmdp)) {
      printf("ERROR: RX %u need %u\r\n", length, sizeof(*cmdp));
    }
    if (CMD_Hello == cmdp->cmd_tag) {
      rc = sendEvent(EVT_Status);
      printf("Hello got %u\r\n", rc);
    } else if (CMD_ResetCounter == cmdp->cmd_tag) {
      counter = cmdp->counter;
      rc = sendEvent(EVT_ResetCounter);
      printf("Reset counter to %u got %u\r\n", counter, rc);
    } else {
      printf("Unrecognized command %u\r\n", cmdp->cmd_tag);
    }
  }

  async event void Alarm.fired () { post periodic_task(); }

  event void PppControl.startDone (error_t error) { }
  event void PppControl.stopDone (error_t error) { }

  event void PppNic.interfaceState (oip_nic_state_t state)
  {
    error_t rc;
    
    printf("PPP nic %02x\r\n", state);
    if (IFF_UP & state) {
      call PppNicLed.on();

      /* PPP link is up: figure out the local and remote ends, and use
       * those as the local and peer addresses. */

      memcpy(localAddress.sin6_addr.s6_addr + 8, call PppNic.interfaceIdentifier(), 8);
      rc = call UdpSocket.bind(localAddress_sap);
      printf("Bind %s got %d\r\n", getnameinfo(localAddress_sap), rc);
      memcpy(remoteAddress.sin6_addr.s6_addr + 8, call PppRemoteIid.interfaceIdentifier(), 8);
      rc = call UdpSocket.connect(remoteAddress_sap);
      printf("Connect %s got %d\r\n", getnameinfo(remoteAddress_sap), rc);
    } else {
      /* PPP link is down.  Release the addresses; next time the link
       * comes up they might change. */

      rc = call UdpSocket.connect(0);
      printf("Release connect got %d\r\n", rc);
      rc = call UdpSocket.bind(0);
      printf("Release bind got %d\r\n", rc);

      call PppNicLed.off();
    }
  }

  event void Boot.booted () {
    /* Basic address initialization: set the address families, address
     * prefixes, service port, and interface.  We'll assign the IID
     * portion of the address when the link comes up. */
    remoteAddress.sin6_family = localAddress.sin6_family = AF_INET6;
    remoteAddress.sin6_addr.s6_addr16[0] = 
      localAddress.sin6_addr.s6_addr16[0] = htons(0xfe80);
    remoteAddress.sin6_port = localAddress.sin6_port = htons(ServicePort);
    remoteAddress.sin6_scope_id = localAddress.sin6_scope_id = call PppNic.id();

    /* For convenience, provide pre-cast generic pointers to the
     * address structures. */
    localAddress_sap = (struct sockaddr*)&localAddress;
    remoteAddress_sap = (struct sockaddr*)&remoteAddress;

    call EventButton.enable();
    post periodic_task();
    call PppControl.start();
  }
}
