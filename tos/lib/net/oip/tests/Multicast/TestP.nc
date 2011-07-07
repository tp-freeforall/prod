#include <stdio.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <net/skbuff.h>

module TestP {
  provides {
    interface Init;
  }
  uses {
    interface Boot;
    interface DeviceIdentity;
    interface SplitControl as Ppp;
    interface IpSocket as UdpSocket;
    interface IpDatagramSocket as UdpDatagramSocket;
    interface NetworkInterface;
    interface Timer<TMilli> as Periodic;
    interface Led as ConnectedLed;
    interface Led as ErrorLed;
    interface Led as RxToggleLed;
    interface Led as TxToggleLed;
  }
  
} implementation {

  enum {
    ServicePort = 49152U + 1972,
    Interval_bms = 2 * 1024,
  };

  union {
      struct sockaddr sa;
      struct sockaddr_in6 s6;
  } serviceAddress_;
  uint16_t txCounter;
  uint16_t rxCounter;
  uint8_t payload[64];
  const odi_t* odi;

  task void sendPacket_task ()
  {
    uint8_t* dp = payload;
    error_t rc;
    
    ++txCounter;
    memcpy(dp, odi, sizeof(*odi));
    dp += sizeof(*odi);
    *(uint16_t*)dp = htons(txCounter);
    dp += sizeof(uint16_t);
    *(uint16_t*)dp = htons(rxCounter);
    dp += sizeof(uint16_t);

    rc = call UdpDatagramSocket.sendto(dp, dp - payload, 0, &serviceAddress_.sa, sizeof(serviceAddress_.s6));
    printf("sendto got %d\r\n", rc);
    call TxToggleLed.toggle();

  }

  event void Periodic.fired () { post sendPacket_task(); }

  command error_t Init.init ()
  {
    int ifindex;
    error_t rc;
    
    ifindex = call NetworkInterface.id();

    serviceAddress_.s6.sin6_family = AF_INET6;
    /* ff02::1 is site all-hosts address */
    serviceAddress_.s6.sin6_addr.s6_addr[0] = 0xff;
    serviceAddress_.s6.sin6_addr.s6_addr[1] = 0x02;
    serviceAddress_.s6.sin6_addr.s6_addr[15] = 0x1;
    serviceAddress_.s6.sin6_scope_id = ifindex;
    serviceAddress_.s6.sin6_port = htons(ServicePort);

    rc = call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_MULTICAST_IF, &ifindex, sizeof(ifindex));
    printf("MulticastIF to %d got %d\r\n", ifindex, rc);
    if (SUCCESS == rc) {
      rc = call UdpSocket.bind(&serviceAddress_.sa);
      printf("Bind address port %u got %d\r\n", ntohs(serviceAddress_.s6.sin6_port), rc);
    }

    return rc;
  }

  event void NetworkInterface.interfaceState (oip_nic_state_t state)
  {
    error_t rc;
    if (IFF_UP & state) {
      rc = call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_JOIN_GROUP, &serviceAddress_.sa, sizeof(serviceAddress_.s6));
      printf("Join to %s got %d\r\n", getnameinfo(&serviceAddress_.sa), rc);
      if (SUCCESS == rc) {
        call Periodic.startPeriodic(Interval_bms);
      }
      if (SUCCESS == rc) {
        call ConnectedLed.on();
      } else {
        call ErrorLed.on();
      }
    } else {
      rc = call UdpSocket.setsockopt(IPPROTO_IPV6, IPV6_LEAVE_GROUP, &serviceAddress_.sa, sizeof(serviceAddress_.s6));
      printf("Leave %s got %d\r\n", getnameinfo(&serviceAddress_.sa), rc);
      call Periodic.stop();
      call ConnectedLed.off();
      call ErrorLed.off();
    }
  }

  event void UdpDatagramSocket.recvfrom (const void* buffer,
                                         size_t length,
                                         int flags,
                                         const struct sockaddr* address,
                                         socklen_t address_len)
  {
    printf("recvmsg %d from %s\r\n", length, getnameinfo(address));
    ++rxCounter;
    call RxToggleLed.toggle();
  }

  event void Ppp.startDone (error_t error)
  {
  }

  event void Ppp.stopDone (error_t error) { }

  event void Boot.booted() {
    error_t rc;

    odi = call DeviceIdentity.get();
    rc = call Init.init();
    rc = call Ppp.start();
  }
}
