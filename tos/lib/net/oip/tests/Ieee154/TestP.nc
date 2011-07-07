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
    interface Timer<TMilli> as Periodic;
  }
} implementation {

  enum {
    WhoAmI_port = 0x1234,
    TxRetryLimit = 4,
  };

  ieee_eui64_t known_iid [] = {
#include "known_iids.h"
    { { 0 } }
  };
  ieee_eui64_t* next_iid;

  struct sockaddr_in6 your_address;
  struct sockaddr_in6 my_address;

  task void sendWhoAmI_task ()
  {
    const uint8_t* data = call NetworkInterface.interfaceIdentifier();
    uint16_t data_len = (7 + call NetworkInterface.interfaceIdentifierLength_bits()) / 8;
    error_t rc;
    int retries;

    memcpy(&your_address, &my_address, sizeof(my_address));
    while (1) {
      if (0 == next_iid->data[0]) {
        printf("Looping back to first known IID\r\n");
        next_iid = known_iid;
        continue;
      }
      if (0 == memcmp(next_iid->data, my_address.sin6_addr.s6_addr + 8, 8)) {
        printf("Skipping my IID\r\n");
        ++next_iid;
        continue;
      }
      break;
    }
    memcpy(your_address.sin6_addr.s6_addr + 8, next_iid->data, 8);
    ++next_iid;

    retries = TxRetryLimit;
    rc = ERETRY;
    while ((ERETRY == rc) && (0 < retries--)) {
      rc = call UdpDatagramSocket.sendto(data, data_len, 0, (struct sockaddr*)&your_address, sizeof(your_address));
    }
    if (SUCCESS != rc) {
      printf("Send got %d after %d tries\r\n", rc, TxRetryLimit - retries);
    }
  }


  event void Periodic.fired () {
    if (IFF_UP & call NetworkInterface.getInterfaceState()) {
      post sendWhoAmI_task();
    } else {
      printf("Periodic: NIC down\r\n");
    }
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
    printf("UDP RX %u bytes from %s\r\n", length, getnameinfo(address));
  }

  event void RadioNicControl.startDone (error_t error)
  {
    printf("Nic startDone %d\r\n", error);
    if (SUCCESS == error) {
      const uint8_t *sp = my_address.sin6_addr.s6_addr + 8;
      const uint8_t *esp = sp + 8;
      error_t rc = call UdpSocket.bind((struct sockaddr*)&my_address);
      printf("Bind to %s got %d\r\n", getnameinfo((struct sockaddr*)&my_address), rc);
      printf("Known IID entry for this board:\r\n\t{ {");
      while (sp < esp) {
        printf(" %02x,", *sp++);
      }
      printf("} } // serial number\r\n");
      post sendWhoAmI_task();
    }
  }

  event void RadioNicControl.stopDone (error_t error)
  {
    printf("Nic stopDone %d\r\n", error);
  }

  void bringUpNic ()
  {
    error_t rc;
    const uint8_t* iid;
    int iid_len_bits;
    uint8_t link_local_prefix[] = { 0xfe, 0x80 };
    const struct sockaddr* llap;

    iid = call NetworkInterface.interfaceIdentifier();
    iid_len_bits = call NetworkInterface.interfaceIdentifierLength_bits();
    printf("Present: NIC at ");
    while (0 < iid_len_bits) {
      printf("%02x", *iid++);
      iid_len_bits -= 8;
    }
    printf("\r\n");
    call NetworkInterface.setInterfaceState(IFF_UP | call NetworkInterface.getInterfaceState());
    llap = call NetworkInterface.locatePrefixBinding(AF_INET6, link_local_prefix, 10);
    printf("Bound to %s\r\n", getnameinfo(llap));
    if (0 != llap) {
      my_address = *(const struct sockaddr_in6*)llap;
      my_address.sin6_port = htons(WhoAmI_port);
    }

    rc = call RadioNicControl.start();
    printf("Start returned %d\r\n", rc);
  }    

  event void Boot.booted()
  {
    next_iid = known_iid;
    bringUpNic();
    call Periodic.startPeriodic(3 * 1024);
  }
}
