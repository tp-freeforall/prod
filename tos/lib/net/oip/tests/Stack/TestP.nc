#include <stdio.h>
#include <arpa/inet.h>
#include "NetworkInterface.h"

module TestP {
  uses {
    interface Boot;
    interface SplitControl as Ppp;
    interface NetworkInterface as PppNic;
    interface NetworkInterfaceIdentifier as RemoteIid;
  }
  
} implementation {

  event void PppNic.interfaceState (oip_nic_state_t state)
  {
    if (IFF_UP & state) {
      const uint16_t* iid = (const uint16_t*)call RemoteIid.interfaceIdentifier();
      const char* colon = "";
      int i;

      printf("PPP NIC is up: remote IID ");
      for (i = 0; i < 4; ++i) {
        printf("%s%04x", colon, ntohs(iid[i]));
        colon = ":";
      }
      printf("\r\n");
    }
  }

  event void Ppp.startDone (error_t error) { }
  event void Ppp.stopDone (error_t error) { }

  event void Boot.booted() {
    error_t rc;

    rc = call Ppp.start();
  }
}
