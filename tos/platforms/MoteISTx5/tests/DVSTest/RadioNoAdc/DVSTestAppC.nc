
#include <Timer.h>

configuration DVSTestAppC {
}
implementation {
  components MainC;
  components LedsC;
  components DVSTestP as App;
  
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components SerialPrintfC;
  
  
  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Timer0 -> Timer0;
  App.Timer1 -> Timer1;
  
  //For tasks
  components TasksC;
  App.Tasks -> TasksC;
  
  //for Radio 
  components ActiveMessageC;
  components new AMSenderC(AM_BLINKTORADIO);
  components new AMReceiverC(AM_BLINKTORADIO);
  
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
  
  //for frequency control
  components Msp430FreqControlC;
  App.FreqControl -> Msp430FreqControlC;
}
