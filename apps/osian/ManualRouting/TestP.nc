#include <stdio.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <netinet/in.h>

module TestP {
  uses {
    interface Boot;
    interface SplitControl as Ieee154Control;
    interface NetworkInterface as Ieee154Nic;
    interface IpSocket as GatewaySocket;
    interface IpDatagramSocket as GatewayDatagram;
    interface IpSocket as ApplicationSocket;
    interface IpDatagramSocket as ApplicationDatagram;
    interface LocalTime<TMilli> as LocalTime_ms;
    interface Alarm<TMilli, uint16_t> as ApplicationAlarm_bms;
    interface Alarm<TMilli, uint16_t> as GatewayAlarm_bms;
    interface Led as TxAppLed;
    interface Led as RxAppLed;
    interface Led as GatewayLed;
#if BUILD_FOR_GATEWAY
    interface SplitControl as PppControl;
    interface NetworkInterface as PppNic;
    interface NetworkInterfaceIdentifier as PppRemoteIid;
#endif /* BUILD_FOR_GATEWAY */
  }
} implementation {

  enum {
    /** Port used for communication with the node serving as a gateway */
    Gateway_port = 50133U,
    /** Port used for application communication */
    Application_port = 54321U,
    /** Maximum number of times to retry UDP transmission when a clear
     * channel is unavailable. */
    RetryLimit_cnt = 5,
    /** Interval, in binary milliseconds, between announcements of gateway status. */
    GatewayAnnounceInterval_bms = 60U * 1024,
  };

  typedef struct gateway_status_t {
    uint8_t up;
    uint8_t gw_iid_len_bits;
    uint8_t gw_iid[8];
  } gateway_status_t;
  bool gwIsUp;

  /** Union to avoid alias violation warnings from gcc */
  typedef union sockaddr_u {
    struct sockaddr sa;
    struct sockaddr_in6 s6;
  } sockaddr_u;

  /** Address for multicast communications with gateway */
  sockaddr_u gwMulticastAddress;
  /** Address for unicast application communication on Ieee154 network */
  sockaddr_u myApplicationAddress;
#if BUILD_FOR_GATEWAY
  /** Service entry point on gateway */
  sockaddr_u gwServiceAddress;
  /** Address for unicast application communication with host */
  sockaddr_u hostApplicationAddress;

  /** Gateway status message */
  gateway_status_t gatewayStatusMessage;
#endif /* BUILD_FOR_GATEWAY */

  event void Ieee154Control.startDone (error_t error)
  {
    error_t rc;
    int retries;
    int scope_id;
      
    scope_id = call Ieee154Nic.id();
    rc = call GatewaySocket.setsockopt(IPPROTO_IPV6, IPV6_MULTICAST_IF, &scope_id, sizeof(scope_id));
#if ! BUILD_FOR_GATEWAY
    printf("MulticastIF to %d got %d\r\n", scope_id, rc);
#endif

    rc = call GatewaySocket.setsockopt(IPPROTO_IPV6, IPV6_JOIN_GROUP, &gwMulticastAddress.sa, sizeof(gwMulticastAddress.s6));
#if ! BUILD_FOR_GATEWAY
    printf("Join to %s got %d\r\n", getnameinfo(&gwMulticastAddress.sa), rc);
#endif

    /* Bind to wildcard address (::) so we receive both link-local and
     * ULA packets. */
    myApplicationAddress.s6.sin6_family = AF_INET6;
    myApplicationAddress.s6.sin6_port = htons(Application_port);
    myApplicationAddress.s6.sin6_scope_id = scope_id;

    /* Bind the application socket */
    rc = call ApplicationSocket.bind(&myApplicationAddress.sa);
#if ! BUILD_FOR_GATEWAY
    printf("Ieee154 ULA %s.%u scope %ld bind got %d\r\n", getnameinfo(&myApplicationAddress.sa), ntohs(myApplicationAddress.s6.sin6_port), myApplicationAddress.s6.sin6_scope_id, rc);
#endif /* BUILD_FOR_GATEWAY */

    /* Solicit gateway information */
    retries = RetryLimit_cnt;
    do {
      rc = call ApplicationDatagram.sendto(0, 0, 0, &gwMulticastAddress.sa, sizeof(gwMulticastAddress.s6));
    } while ((ERETRY == rc) && (0 < --retries));
#if ! BUILD_FOR_GATEWAY
    printf("GW solicitation got %d with %d\r\n", rc, retries);
#endif /* BUILD_FOR_GATEWAY */
  }
  event void Ieee154Control.stopDone (error_t error) { }
  event void Ieee154Nic.interfaceState (oip_nic_state_t state) { }

  task void gatewayAlarm_task ()
  {
#if BUILD_FOR_GATEWAY
    int retries = RetryLimit_cnt;
    error_t rc;
    
    do {
      rc = call GatewayDatagram.sendto(&gatewayStatusMessage, sizeof(gatewayStatusMessage), 0, &gwMulticastAddress.sa, sizeof(gwMulticastAddress.s6));
    } while ((ERETRY == rc) && (0 < --retries));
    //printf("GWA %d after %d\r\n", rc, retries);
    call GatewayAlarm_bms.start(GatewayAnnounceInterval_bms);
#else
#endif
  }

  async event void ApplicationAlarm_bms.fired () { }
  async event void GatewayAlarm_bms.fired ()
  {
    post gatewayAlarm_task();
  }

  void processGatewayMessage (const gateway_status_t* gws,
                              const struct sockaddr* address,
                              socklen_t address_len)
  {
      gwIsUp = gws->up;
#if ! BUILD_FOR_GATEWAY
      printf("GW status from %s: %d", getnameinfo(address), gwIsUp);
      if (gwIsUp && gws->gw_iid_len_bits) {
	size_t iid_len;
	const uint8_t* dp = gws->gw_iid;
	printf(" iid %d bits: ", gws->gw_iid_len_bits);
	iid_len = (7 + gws->gw_iid_len_bits) / 8;
	if (iid_len > sizeof(gws->gw_iid)) {
	  iid_len = sizeof(gws->gw_iid);
	}
	while (iid_len--) {
	  printf(" %02x", 0xff & *dp++);
	}
      }
      printf("\r\n");
#endif /* BUILD_FOR_GATEWAY */
      call GatewayLed.set(gwIsUp);
  }

  event void ApplicationDatagram.recvfrom (const void* buffer,
                                           size_t length,
                                           int flags,
                                           const struct sockaddr* address,
                                           socklen_t address_len)
  {
#if ! BUILD_FOR_GATEWAY
    printf("RX %u from %s\r\n", length, getnameinfo(address));
#endif /* BUILD_FOR_GATEWAY */
    if (sizeof(gateway_status_t) == length) {
      processGatewayMessage((const gateway_status_t*)buffer, address, address_len);
    }
  }

  event void GatewayDatagram.recvfrom (const void* buffer,
                                       size_t length,
                                       int flags,
                                       const struct sockaddr* address,
                                       socklen_t address_len)
  {
#if BUILD_FOR_GATEWAY
    int retries = RetryLimit_cnt;
    error_t rc;
    
    call RxAppLed.toggle();
    do {
      rc = call GatewayDatagram.sendto(&gatewayStatusMessage, sizeof(gatewayStatusMessage), 0, address, address_len);
    } while ((ERETRY == rc) && (0 < --retries));
    if (SUCCESS == rc) {
      call TxAppLed.toggle();
    }
#else /* BUILD_FOR_GATEWAY */
    if (sizeof(gateway_status_t) == length) {
      processGatewayMessage((const gateway_status_t*)buffer, address, address_len);
    }
#endif /* BUILD_FOR_GATEWAY */
  }

#if BUILD_FOR_GATEWAY
  event void PppControl.startDone (error_t error) { }
  event void PppControl.stopDone (error_t error) { }
  event void PppNic.interfaceState (oip_nic_state_t state)
  {
    if (IFF_UP & state) {
      gwIsUp = TRUE;
      call GatewayLed.on();
    } else {
      gwIsUp = FALSE;
      call GatewayLed.off();
    }
    memset(&gatewayStatusMessage, 0, sizeof(gatewayStatusMessage));
    gatewayStatusMessage.up = gwIsUp;
    if (gwIsUp) {
      const uint8_t* iid = call PppRemoteIid.interfaceIdentifier();
      gateway_status_t* mp = &gatewayStatusMessage;
      if (iid) {
	size_t iid_len;
	mp->gw_iid_len_bits = call PppRemoteIid.interfaceIdentifierLength_bits();
	iid_len = (7 + mp->gw_iid_len_bits) / 8;
	if (iid_len > sizeof(mp->gw_iid)) {
	  iid_len = sizeof(mp->gw_iid);
	}
	memcpy(mp->gw_iid, iid, iid_len);
      }
    }

    post gatewayAlarm_task();
  }
#endif /* BUILD_FOR_GATEWAY */

  event void Boot.booted () {
    error_t rc;
    
    gwMulticastAddress.s6.sin6_family = AF_INET6;
    gwMulticastAddress.s6.sin6_addr.s6_addr16[0] = htons(0xFF02);
    gwMulticastAddress.s6.sin6_addr.s6_addr16[7] = htons(2);
    gwMulticastAddress.s6.sin6_port = htons(Gateway_port);
    gwMulticastAddress.s6.sin6_scope_id = call Ieee154Nic.id();
    
    rc = call GatewaySocket.bind(&gwMulticastAddress.sa);
#if ! BUILD_FOR_GATEWAY
    printf("Bind gateway to %s.%u returned %d\r\n",
           getnameinfo(&gwMulticastAddress.sa),
           ntohs(gwMulticastAddress.s6.sin6_port),
           rc);
#endif
    call Ieee154Control.start();
#if BUILD_FOR_GATEWAY
    call PppControl.start();
#endif /* BUILD_FOR_GATEWAY */
  }
}
