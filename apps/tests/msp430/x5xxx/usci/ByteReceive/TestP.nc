#include <stdio.h>

/**
 * Manual test for UartByte receive functions.
 *
 * Install to a device and configure the serial port.  Cat the serial
 * port in one window, and in the other send it data:
 *  % cat /dev/ttyUSB2
 *  % echo 0123456789abcdefghijklmnopqrstuvwxyz > /dev/ttyUSB2
 *
 * NOTE: To make this work with human reaction times, the USCI
 * implementation allows you to set the ByteTimeScaleFactor to 1000 in
 * the implementation source.  Don't forget to put it back to 1 after
 * testing.
 *
 * NOTE: Experimentally, this is an unreliable test.  Even when the
 * UART is waiting, many of the transmitted characters are lost; the
 * first one returned might be 'b' or even 'q'.  This behavior is
 * present with the tmote implementation as well.
 */
module TestP @safe()
{
  uses {
    interface Boot;
    interface LocalTime<TMilli> as LocalTime_mis;
    interface UartByte;
  }
}
implementation
{
  
  const uint8_t verbose = 0;
  const uint8_t wait_times_bt[] = { 0, 32, 128, 255 };
  const uint8_t num_wait_times_bt = sizeof(wait_times_bt) / sizeof(*wait_times_bt);

  event void Boot.booted()  {
    uint8_t wti = 0;

    printf("# Starting UartByte receive test.\r\n");
    while (1) {
      uint8_t wait_bt = wait_times_bt[wti];
      uint32_t start_mis;
      uint32_t end_mis;
      uint8_t byte = '@';
      error_t rc;
      
      if (verbose) {
        printf("Waiting %d byte times for input\r\n", wait_bt);
      }
      start_mis = call LocalTime_mis.get();
      rc = call UartByte.receive(&byte, wait_bt);
      end_mis = call LocalTime_mis.get();
      if (verbose || (SUCCESS == rc)) {
        printf("After %lu mis, result %d, byte value %d ('%c')\r\n", (end_mis - start_mis), rc, byte, byte);
      }
      if (++wti >= num_wait_times_bt) {
        wti = 0;
      }
    }
  }

}

