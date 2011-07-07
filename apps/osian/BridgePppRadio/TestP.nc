#include <stdio.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <net/skbuff.h>
#include <net/ipv6.h>
#include "OipLinkLayer.h"

module TestP {
  uses {
    interface Boot;
    interface SplitControl as RadioControl;
    interface NetworkInterface as RadioNic;
#if OIP_LINK_LAYER == OIP_LINK_LAYER_IEEE154
    interface Ieee154Address;
#endif /* OIP_LINK_LAYER_IEEE154 */
    interface SplitControl as PppControl;
    interface NetworkInterface as PppNic;
    interface NetworkInterfaceIdentifier as PppLocalIid;
    interface NetworkInterfaceIdentifier as PppRemoteIid;
    interface IpSocket;
    interface IpSocketMsg;
    interface Led as PppLed;
    interface Led as PppToRadioLed;
    interface Led as RadioToPppLed;
  }
} implementation {

  enum {
    /** Length of the PPP IID, in octets */
    PPP_IID_LENGTH = 8,
  };

  const char* ifname[1+OIP_NETWORK_INTERFACE_MAX];

  typedef union socket_u {
    struct sockaddr sa;
    struct sockaddr_in6 s6;
  } socket_u;

  socket_u rawAddress;
  const uint8_t* localIid_ppp;
  const uint8_t* remoteIid_ppp;

  event void RadioControl.startDone (error_t error) { }
  event void RadioControl.stopDone (error_t error) { }

#if OIP_LINK_LAYER == OIP_LINK_LAYER_IEEE154
  socket_u bridgedAddress_;

  async event void Ieee154Address.changed () { } 
#endif /* OIP_LINK_LAYER_IEEE154 */

  bool matchLinkLocal (const struct in6_addr* iap,
                          const uint8_t* iid)
  {
    static uint8_t fe80[8] = { 0xfe, 0x80 };

    if (0 != memcmp(iap->s6_addr, fe80, sizeof(fe80))) {
      return FALSE;
    }
    return 0 == memcmp(iap->s6_addr + sizeof(fe80), iid, PPP_IID_LENGTH);
  }

  void dumpIid (const uint8_t* iid) {
    int i = PPP_IID_LENGTH;
    while (i--) {
      printf(" %02x", iid[PPP_IID_LENGTH - i]);
    }
  }

  event void RadioNic.interfaceState (oip_nic_state_t state)
  {
    printf("Radio link state %04x\r\n", state);
  }

  event void PppControl.startDone (error_t error) { }
  event void PppControl.stopDone (error_t error) { }
  event void PppNic.interfaceState (oip_nic_state_t state)
  {
    error_t rc;

    printf("PPP link state %04x\r\n", state);
    if (IFF_UP & state) {
      localIid_ppp = call PppLocalIid.interfaceIdentifier();
      remoteIid_ppp = call PppRemoteIid.interfaceIdentifier();

      printf("UP: PPP nic id %d, Radio nic id %d\r\n",
             call PppNic.id(),
             call RadioNic.id());

      printf("Remote IID:");
      dumpIid(remoteIid_ppp);
      printf("; Local IID:");
      dumpIid(localIid_ppp);
      printf("\r\n");

#if OIP_LINK_LAYER_IEEE154 == OIP_LINK_LAYER
      /* The Ieee154 link layer will filter incoming packets based on
       * the short address, regardless of the fact that we have the
       * NIC configured for promiscuous mode.  In order to receive
       * packets addressed to the host, we have to assign the same
       * link-local address to the radio NIC as is used for the remote
       * end of the PPP link.  That means we set the radio link-layer
       * PAN to be the IEEE154 subnet, but use the IID of the PPP
       * remote as its address; furthermore, we bind the NIC to the
       * bridged address too.  */
      call Ieee154Address.setAddress(OSIAN_ULA_SUBNET_IEEE154, ntohs(*(uint16_t*)(remoteIid_ppp + PPP_IID_LENGTH - 2)));
      printf("IEEE154 address set to %4x.%4x\r\n",
             call Ieee154Address.panId(),
             call Ieee154Address.shortAddress());

      memcpy(bridgedAddress_.s6.sin6_addr.s6_addr + 8, remoteIid_ppp, PPP_IID_LENGTH);
      bridgedAddress_.s6.sin6_scope_id = call RadioNic.id();
      rc = call RadioNic.bindAddress(&bridgedAddress_.sa);
      printf("Bridging Radio to %s got %d\r\n", getnameinfo(&bridgedAddress_.sa), rc);
#endif /* OIP_LINK_LAYER_IEEE154 */

      rc = call RadioControl.start();
      printf("Radio start got %d\r\n", rc);
      call PppLed.on();
    } else {

#if OIP_LINK_LAYER_IEEE154 == OIP_LINK_LAYER
      if (0 != bridgedAddress_.s6.sin6_scope_id) {
        /* Revoke the address of the radio */
        rc = call RadioNic.releaseAddress(&bridgedAddress_.sa);
        printf("Unbridged Radio to %s got %d\r\n", getnameinfo(&bridgedAddress_.sa), rc);
        bridgedAddress_.s6.sin6_scope_id = 0;
      }
#endif /* OIP_LINK_LAYER_IEEE154 */

      rc = call RadioControl.stop();
      localIid_ppp = remoteIid_ppp = 0;
      call PppLed.off();
    }
  }

  event void IpSocketMsg.recvmsg (const struct msghdr* message,
                                  int flags)
  {
    struct sk_buff* skb = message->msg_control;
    socket_u bsrc;
    socket_u bdst;
    struct sockaddr_in6* s6p = (struct sockaddr_in6*)(skb->src);
    struct sockaddr_in6* d6p = (struct sockaddr_in6*)(skb->dst);
    struct sk_buff bskb;
    struct msghdr bmessage;
    int rc;

#if 0
    printf("Bridge got %d msg on %d: %s%%%s", skb->proto, skb->nic_id, getnameinfo(skb->src), ifname[s6p->sin6_scope_id]);
    printf(" to %s%%%s\r\n", getnameinfo(skb->dst), ifname[d6p->sin6_scope_id]);
    {
      int i;
      for (i = 0; i < message->msg_iovlen; ++i) {
        struct iovec* iovp = message->msg_iov + i;
        uint8_t* dp = iovp->iov_base;
        uint8_t* dpe = dp + iovp->iov_len;
        printf("iptx[%d] ", i);
        while (dp < dpe) {
          printf(" %02x", *dp++);
        }
        printf("\r\n");
      }
    }
#endif
    if (call PppNic.id() == skb->nic_id) {
      /* Drop messages that are addressed to the bridge */
      if (matchLinkLocal(&d6p->sin6_addr, localIid_ppp)) {
        return;
      }
      call PppToRadioLed.toggle();
    } else {
#if OIP_LINK_LAYER_IEEE154 != OIP_LINK_LAYER
      /* Drop messages that are link-local and not addressed to the
       * remote. */
      if (IN6_IS_ADDR_LINKLOCAL(&d6p->sin6_addr)
	  && ! matchLinkLocal(&d6p->sin6_addr, remoteIid_ppp)) {
        return;
      }
#endif /* OIP_LINK_LAYER_IEEE154 */

      call RadioToPppLed.toggle();
    }

    memset(&bmessage, 0, sizeof(bmessage));
    bmessage.msg_name = &bdst.sa;
    bmessage.msg_namelen = sizeof(bdst.s6);
    bmessage.msg_iov = message->msg_iov;
    bmessage.msg_iovlen = message->msg_iovlen;
    bmessage.msg_control = &bskb;
    bmessage.msg_controllen = sizeof(bskb);
    bmessage.msg_flags = message->msg_flags;
    bmessage.xmsg_sname = &bsrc.sa;
    
    memset(&bskb, 0, sizeof(bskb));
    bskb.nic_id = 0x03 ^ skb->nic_id;
    bskb.proto = skb->proto;
    bskb.src = &bsrc.sa;
    bskb.dst = &bdst.sa;

    memcpy(&bsrc.s6, s6p, sizeof(*s6p));
    memcpy(&bdst.s6, d6p, sizeof(*d6p));
    bsrc.s6.sin6_scope_id = bdst.s6.sin6_scope_id = bskb.nic_id;

    rc = call IpSocketMsg.sendmsg(&bmessage, flags);
    // printf("Retransmit got %d\r\n", rc);
  }

  event void Boot.booted () {
    ifname[0] = "NONE";
    ifname[call PppNic.id()] = "ppp";
    ifname[call RadioNic.id()] = "rf1a";

    call RadioNic.setInterfaceState(IFF_PROMISC | call RadioNic.getInterfaceState());

    rawAddress.s6.sin6_family = AF_INET6;
    call IpSocket.bind(&rawAddress.sa);

    call PppNic.setInterfaceState(IFF_PROMISC | call PppNic.getInterfaceState());
    call PppControl.start();
  }
}
