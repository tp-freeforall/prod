configuration PseudoSerialC {
  provides {
    interface StdControl;
    interface UartStream;
    interface UartByte;
    interface PseudoSerial;
  }
} implementation {
  components PseudoSerialP;
  StdControl = PseudoSerialP;
  UartStream = PseudoSerialP;
  UartByte = PseudoSerialP;
  PseudoSerial = PseudoSerialP;
}
