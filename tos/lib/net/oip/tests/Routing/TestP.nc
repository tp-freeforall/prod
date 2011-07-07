/** Application receives HDLC-encoded frames over the serial port,
 * and prints a summary of what it got. */
#include <stdio.h>
#include <arpa/inet.h>
module TestP {
  uses {
    interface Boot;
    interface SplitControl as PppControl;
    interface SplitControl as Ieee154Control;
    interface NetworkInterface as PppNic;
    interface NetworkInterface as Ieee154Nic;
  }
  
} implementation {

  event void PppControl.startDone (error_t error)
  {
  }
  event void PppControl.stopDone (error_t error) { }

  event void Ieee154Control.startDone (error_t error)
  {
    printf("Radio started: %d\r\n", error);
  }
  event void Ieee154Control.stopDone (error_t error) { }

  event void PppNic.interfaceState (oip_nic_state_t state)
  {
    const uint16_t* iidp = (const uint16_t*)call PppNic.interfaceIdentifier();
    int iidl = call PppNic.interfaceIdentifierLength_bits();
    printf("Ppp state %02x : iid :", state);
    while (0 < iidl) {
      printf(":%04x", htons(*iidp++));
      iidl -= 16;
    }
    printf("\r\n");
    if (IFF_UP & state) {
      (void)call Ieee154Control.start();
    }
  }

  event void Ieee154Nic.interfaceState (oip_nic_state_t state)
  {
    const uint16_t* iidp = (const uint16_t*)call Ieee154Nic.interfaceIdentifier();
    int iidl = call Ieee154Nic.interfaceIdentifierLength_bits();
    printf("Ieee154 state %02x : iid :", state);
    while (0 < iidl) {
      printf(":%04x", htons(*iidp++));
      iidl -= 16;
    }
    printf("\r\n");
  }

  event void Boot.booted() {
    (void)call PppControl.start();
    // (void)call Ieee154Control.start();
  }
}
