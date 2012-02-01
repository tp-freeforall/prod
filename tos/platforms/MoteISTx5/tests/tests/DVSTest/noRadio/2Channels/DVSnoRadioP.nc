#include <stdio.h>
#include "Msp430Adc12.h"

#ifdef ADC12_TIMERA_ENABLED
#undef ADC12_TIMERA_ENABLED
#endif

#define ADC_SAMPLE_TIME 10 //miliseconds
#define ITERATIONS 900
#define DEADLINE 5000
#define SAMPLES 16

module DVSnoRadioP {
  provides interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfigure;
  uses interface Boot;
  uses interface Leds;
  uses interface Tasks;
  uses interface FreqControl;
  uses interface Msp430Adc12Overflow as overflow;
  uses interface Msp430Adc12MultiChannel as adc;
  uses interface Resource as AdcResource;
}
implementation {

  uint16_t adb[SAMPLES];
  //uint8_t count = 0;
  uint32_t Freq = 1000000;
  uint32_t ActFreq = 0;
  uint32_t EndFreq = 25000000; 
  uint32_t Step = 500000;
  uint32_t timeStart = 0;
  uint32_t timeEnd = 0;
  uint16_t Number = 0;
  bool AdcDone = FALSE;
    
//prototypes
  void printadb();
  void printfFloat(float toBePrinted);
  void showerror();
  error_t configureAdc();
  void frequency_sweep();
  
  msp430adc12_channel_config_t adcconfig = {

    inch: INPUT_CHANNEL_A1,
    sref: REFERENCE_VREFplus_AVss,
    ref2_5v: REFVOLT_LEVEL_2_5,
    adc12ssel: SHT_SOURCE_ADC12OSC,
    adc12div: SHT_CLOCK_DIV_1,
    sht: SAMPLE_HOLD_16_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_ACLK,
    sampcon_id: SAMPCON_CLOCK_DIV_1
  };
  
  adc12memctl_t channelconfig = {
    inch: INPUT_CHANNEL_A2,
    sref: REFVOLT_LEVEL_2_5, 
    eos: 1
  };
  
  async command const msp430adc12_channel_config_t* AdcConfigure.getConfiguration(){
    return &adcconfig; // must not be changed
  }
  
  event void Boot.booted() {      
    //request the adc
    call AdcResource.request();
 
  }
  void uwait(uint32_t u) {
    uint32_t t0 = TA0R;
    while((TA0R - t0) <= u);
  }
  
  event void AdcResource.granted(){
    error_t e = FAIL;
      while(e != SUCCESS){
        e = configureAdc();
      }
        /*
         * Adc is configured, now init the system
         */ 
      printf("Number#,Frequency(Hz),Time(ms),I(12bit), V(12bit)\n");
      if(call FreqControl.setMCLKFreq(Freq) != SUCCESS)
				printf("Could not change the frequency to: %lu Hz. \r\n", Freq);
			else
				atomic ActFreq = Freq;
      
      call adc.getData();

      uwait(1024*5);
      atomic if(AdcDone){
        printadb();
        AdcDone=FALSE;
      }
      call Tasks.getFibonacci(ITERATIONS, DEADLINE);
  } 
  
  event void Tasks.FibonacciDone(uint16_t iterations, uint32_t startTime, uint32_t endTime, error_t status){
    atomic timeEnd = startTime;
    atomic timeStart = endTime;
    
    if(Freq<EndFreq){
      Freq=Freq+Step;
      if(call FreqControl.setMCLKFreq(Freq) != SUCCESS)
				printf("Could not change the frequency to: %lu Hz. \r\n", Freq);
			else{
        atomic ActFreq = Freq;
        atomic Number++; // increment the number of sequences calculated
      }
      call adc.getData();
      
      call Tasks.getFibonacci(ITERATIONS, DEADLINE);
      atomic if(AdcDone){
        printadb();
        AdcDone = FALSE;
      }
    }
    else{
      atomic Number++; // increment the number of sequences calculated
      call adc.getData();
      uwait(1024*5);
      atomic if(AdcDone){
        printadb();
        AdcDone = FALSE;
      }
    }
    
    if(Freq>=EndFreq){
      call Leds.led2On();
      return;
    }
  }
  
  event void Tasks.FibonacciIterationDone(){
  }
  
  async event void overflow.conversionTimeOverflow(){ }

  async event void overflow.memOverflow(){ }
 
   async event void adc.dataReady(uint16_t *buffer, uint16_t numSamples){
    AdcDone = TRUE;
    
  }
  
  
//functions
 void printadb(){
    uint8_t i;
    uint32_t currentMean = 0;
    uint32_t voltageMean = 0;
    //float Gain = 37.5; //(Gm*Rout)
    //float refVolt = 2.5;
    //float Nmax = 4095;
    //float Rsense = 1.01;
    
    for(i = 0; i < SAMPLES; i+=2){
      currentMean += adb[i];
      voltageMean += adb[i+1];
    }
      currentMean /= SAMPLES/2;  //bits
      voltageMean /= SAMPLES/2; // bits
      //currentMean *= refVolt/Nmax; //value in Volts
      //voltageMean *= refVolt/Nmax; //value in Volts
      
      //currentMean = (currentMean*1000)/(Gain*Rsense); //current in mA, Rsense = 1.01 Ohm
      //voltageMean *= 2; // multiply by 2 to get total battery voltage
      
      printf("%d,%lu,%lu,%lu,%lu\n", Number, ActFreq, timeEnd, currentMean, voltageMean);
  }


  void printfFloat(float toBePrinted) {
	uint32_t fi, f0, f1, f2;
	float f = toBePrinted;

		// integer portion.
		fi = (uint32_t) f;

		// decimal portion...get index for up to 3 decimal places.
		f = f - ((float) fi);
		f0 = f*10;   f0 %= 10;
		f1 = f*100;  f1 %= 10;
		f2 = f*1000; f2 %= 10;
		printf("%ld.%d%d%d", fi, (uint8_t) f0, (uint8_t) f1,  (uint8_t) f2);
  } 
  
  void showerror(){
    call Leds.led0On();
  }
  
  error_t configureAdc(){
    error_t e;
      e = call adc.configure(&adcconfig, &channelconfig, 1, adb, SAMPLES, 0);
    if(e != SUCCESS){
		showerror();
        printf("error %d\n", e);
    }
    return e;
  }
  
}
