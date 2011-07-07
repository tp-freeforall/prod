configuration TestAppC {
} implementation {
  components TestP;
  components MainC;

  TestP.Boot -> MainC;
  
  components PseudoSerialC;
  TestP.UartStream -> PseudoSerialC;
  TestP.PseudoSerial -> PseudoSerialC;

  components SerialPrintfC;
}
