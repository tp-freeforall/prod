#include <Timer.h>

configuration RadioAdcC {
}
implementation {
  components MainC;
  components LedsC;
  components RadioAdcP as App;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components SerialPrintfC;
  
  App.Boot -> MainC;
  App.Leds -> LedsC;
  
  //timers
  App.Timer0 -> Timer0;
  App.Timer1 -> Timer1;
  
  //tasks (fibonacci)
  components TasksC;
  App.Tasks -> TasksC;
  
  //ADC
  components new Msp430Adc12ClientAutoRVGC() as adc;
  App.adc -> adc;
  App.AdcResource -> adc;
  adc.AdcConfigure -> App.AdcConfigure;
  
  //Frequency control
  components Msp430FreqControlC;
  App.FreqControl -> Msp430FreqControlC;
  
  //Radio 
  components ActiveMessageC;
  components new AMSenderC(AM_BLINKTORADIO);
  components new AMReceiverC(AM_BLINKTORADIO);
  
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
}
