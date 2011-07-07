#include <stdio.h>

module TestP {
  uses {
    interface Boot;
    interface UartStream;
    interface PseudoSerial;
  }
} implementation {

  uint8_t rx_buffer[512];
  unsigned int nrx;

  async event void UartStream.sendDone (uint8_t* buf,
                                        uint16_t len,
                                        error_t err) { }
  async event void UartStream.receivedByte (uint8_t byte)
  {
    rx_buffer[nrx++] = byte;
  }
  
  async event void UartStream.receiveDone (uint8_t* buf, uint16_t len, error_t err) { }

  void testStreamByteEvents ()
  {
    call PseudoSerial.feedUartStream("Hello", 5);
    printf("Received buffer %d: %s\r\n", nrx, rx_buffer);
  }

  event void Boot.booted () {
    printf("Here I am.\r\n");
    testStreamByteEvents();
  }
}
