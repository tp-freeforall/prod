
#include <Timer.h>

configuration DVSnoRadioC {
}
implementation {
  components MainC;
  components LedsC;
  components DVSnoRadioP as App;
  components SerialPrintfC;
  
  App.Boot -> MainC;
  App.Leds -> LedsC;
  
  //For tasks (fibonacci)
  components TasksC;
  App.Tasks -> TasksC;
  
  //For ADC
  components new Msp430Adc12ClientAutoRVGC() as adc;
  App.adc -> adc;
  App.AdcResource -> adc;
  adc.AdcConfigure -> App.AdcConfigure;
  
  //For frequency control
  components Msp430FreqControlC;
  App.FreqControl -> Msp430FreqControlC;
  
  //For UART
  //components PlatformSerialC;
  //App.UartStream -> PlatformSerialC;
}
