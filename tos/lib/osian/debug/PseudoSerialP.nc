module PseudoSerialP {
  provides {
    interface StdControl;
    interface UartStream;
    interface UartByte;
    interface PseudoSerial;
  }
} implementation {

#ifndef PSEUDOSERIAL_MAX_TX_BUFFER
#define PSEUDOSERIAL_MAX_TX_BUFFER 512
#endif /* PSEUDOSERIAL_MAX_TX_BUFFER */

  bool inhibit_rx;
  uint8_t* rx_buffer;
  uint16_t rx_buffer_idx;
  uint16_t rx_buffer_length;

  command error_t StdControl.start () { return SUCCESS; }
  command error_t StdControl.stop () { return SUCCESS; }

  async command error_t UartStream.send (uint8_t* buf, uint16_t len) { return FAIL; }
  // async event void UartStream.sendDone (uint8_t* buf, uint16_t len, error_t err) { }

  async command error_t UartStream.enableReceiveInterrupt ()
  {
    inhibit_rx = FALSE;
    return SUCCESS;
  }

  async command error_t UartStream.disableReceiveInterrupt ()
  {
    inhibit_rx = TRUE;
    return SUCCESS;
  }
  // async event void UartStream.receivedByte (uint8_t byte) { }

  async command error_t UartStream.receive (uint8_t* buf, uint16_t len)
  {
    if (rx_buffer) {
      return EBUSY;
    }
    rx_buffer = buf;
    rx_buffer_idx = 0;
    rx_buffer_length = len;
    return SUCCESS;
  }

  // async event void UartStream.receiveDone (uint8_t* buf, uint16_t len, error_t err) { }
  
  async command error_t UartByte.send (uint8_t byte) { return FAIL; }
  async command error_t UartByte.receive (uint8_t* byte, uint8_t timeout) { return FAIL; }

  command error_t PseudoSerial.feedUartByte (uint8_t byte)
  {
    if (rx_buffer) {
      rx_buffer[rx_buffer_idx++] = byte;
      if (rx_buffer_idx == rx_buffer_length) {
        uint8_t* srxb = rx_buffer;
        rx_buffer = 0;
        rx_buffer_length = 0;
        signal UartStream.receiveDone(srxb, rx_buffer_idx, SUCCESS);
      }
    }
    if (! inhibit_rx) {
      signal UartStream.receivedByte(byte);
    }
    return SUCCESS;
  }


  command error_t PseudoSerial.feedUartStream (const uint8_t* data,
                                               unsigned int len)
  {
    const uint8_t* dp = data; 
    const uint8_t* dpe = dp + len;
    while (dp < dpe) {
      call PseudoSerial.feedUartByte(*dp++);
    }
    return SUCCESS;
  }

  command unsigned int PseudoSerial.consumeUartStream (uint8_t* data,
                                                       unsigned int max_len)
  {
    return FAIL;
  }
  
}
