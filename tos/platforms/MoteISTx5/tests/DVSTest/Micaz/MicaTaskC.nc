configuration MicaTaskC {
}
implementation {
  components MainC;
  components LedsC;
  components MicaTaskP as App;
  
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  
  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Timer0 -> Timer0;
  App.Timer1 -> Timer1;
  
  //for Radio 
  components ActiveMessageC;
  components new AMSenderC(AM_BLINKTORADIO);
  components new AMReceiverC(AM_BLINKTORADIO);
  
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
}
