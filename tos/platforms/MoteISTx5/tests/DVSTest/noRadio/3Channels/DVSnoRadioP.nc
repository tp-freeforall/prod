#include <stdio.h>
#include "Msp430Adc12.h"

#ifdef ADC12_TIMERA_ENABLED
#undef ADC12_TIMERA_ENABLED
#endif

#define ADC_SAMPLE_TIME 10 //miliseconds
#define ITERATIONS 5000
#define DEADLINE 9000
#define SAMPLES 15
#define FREQ_25MHz 25000000
#define FREQ_1MHz 1000000
#define FREQ_STEP FREQ_1MHz
#define SWEEP_REPOST_DELAY 50
#define UP

module DVSnoRadioP {
  provides interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfigure;
  uses interface Boot;
  uses interface Leds;
  uses interface Tasks;
  uses interface FreqControl;
  uses interface Msp430Adc12Overflow as overflow;
  uses interface Msp430Adc12MultiChannel as adc;
  uses interface Resource as AdcResource;
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  uses interface Timer<TMilli> as Timer2;
}
implementation {

  uint16_t adb[SAMPLES];
  //uint8_t count = 0;
  #ifdef UP
  uint32_t Freq = FREQ_1MHz;
  uint32_t EndFreq = FREQ_25MHz;
  uint32_t ActFreq = FREQ_1MHz;
  #else
  uint32_t Freq = FREQ_25MHz;
  uint32_t EndFreq = FREQ_1MHz;
  uint32_t ActFreq = FREQ_25MHz;
  #endif
  uint32_t timeStart = 0;
  uint32_t timeEnd = 0;
  uint16_t Number = 0;
  uint32_t adcStartTime, adcEndTime;
  bool fibDone = FALSE;
//prototypes
  //void printadb();
  void printfFloat(float toBePrinted);
  void showerror();
  error_t configureAdc();
  
  msp430adc12_channel_config_t adcconfig = {

    inch: INPUT_CHANNEL_A1,
    sref: REFERENCE_VREFplus_AVss,
    ref2_5v: REFVOLT_LEVEL_1_5,
    adc12ssel: SHT_SOURCE_ACLK,
    adc12div: SHT_CLOCK_DIV_1,
    sht: SAMPLE_HOLD_64_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_ACLK,
    sampcon_id: SAMPCON_CLOCK_DIV_1
  };
  
  /*adc12memctl_t channelconfig = {
    inch: INPUT_CHANNEL_A2,
    sref: REFVOLT_LEVEL_2_5, 
    eos: 1
  };*/
  
  adc12memctl_t channelconfig [] = { 
    {INPUT_CHANNEL_A2, REFVOLT_LEVEL_1_5, 0},
    {INPUT_CHANNEL_A3, REFVOLT_LEVEL_1_5, 1}
  };
  adc12memctl_t * adcchannelconfig = (adc12memctl_t *) channelconfig;
  
  task void delaySweep(){
    call Timer1.startOneShot(SWEEP_REPOST_DELAY);
  }
  
  task void sweep(){
    uint32_t t0 = 0;
    uint32_t now = 0;
    
    #ifdef UP
    if(Freq<=EndFreq){
    #else
    if(Freq>=EndFreq){
    #endif
    atomic call Timer2.startOneShot(600);
    atomic adcStartTime=call Timer2.gett0();
    //atomic adcStartTime=call Timer0.getdt();
    call adc.getData();
      if(call FreqControl.setMCLKFreq(Freq) != SUCCESS)
				printf("Could not change the frequency to: %lu Hz. \r\n", Freq);
			else{
        ActFreq = Freq;
        Number++; // increment the number of sequences calculated
      }
      //printf("adc.getdata; ");
      //printf("tasks.getfib\n ");
      atomic fibDone = FALSE;
      call Tasks.getFibonacci(ITERATIONS, DEADLINE);
    }
    else{
      call Leds.led2On();
      call Timer0.stop();
		  t0=call Timer0.gett0();
		  now=call Timer0.getNow();
      //printf("sweep: ");
      printf("app end time: %lu\n", now-t0);
    }
    #ifdef UP
    Freq+=FREQ_STEP;
    #else
    Freq-=FREQ_STEP;
    #endif
  }
  
 task void printadb(){
    uint8_t i;
    uint32_t currentMean = 0;
    uint32_t voltageMean = 0;
    uint32_t vcoreMean = 0;
    //float Gain = 37.5; //(Gm*Rout)
    //float refVolt = 2.5;
    //float Nmax = 4095;
    //float Rsense = 1.01;
    //printf("print adb: ");
    for(i = 0; i < SAMPLES; i+=3){
      currentMean += adb[i];
      voltageMean += adb[i+1];
      vcoreMean += adb[i+2];
    }
      currentMean /= SAMPLES/3;  //bits
      voltageMean /= SAMPLES/3; // bits
      vcoreMean /= SAMPLES/3; // bits
      //currentMean *= refVolt/Nmax; //value in Volts
      //voltageMean *= refVolt/Nmax; //value in Volts
      
      //currentMean = (currentMean*1000)/(Gain*Rsense); //current in mA, Rsense = 1.01 Ohm
      //voltageMean *= 2; // multiply by 2 to get total battery voltage
      
      atomic printf("%d,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu\n", Number, ActFreq, timeStart, timeEnd, currentMean, voltageMean, vcoreMean, adcStartTime, adcEndTime);
  }
  
  async command const msp430adc12_channel_config_t* AdcConfigure.getConfiguration(){
    return &adcconfig; // must not be changed
  }
  
  event void Boot.booted() {      
    P1DIR |= 0x40;  // P1.6 to output direction
    P2DIR |= 0x01;  // P2.0 to output direction
    P1SEL |= 0x40;  // P1.6 Output SMCLK
    P2SEL |= 0x01;  // 2.0 Output MCLK
    //request the adc
    call AdcResource.request();
 
  }
  void uwait(uint32_t u) {
    uint32_t t0 = TA0R;
    while((TA0R - t0) <= u);
  }
  
  event void AdcResource.granted(){
    error_t e = FAIL;
    uint32_t maxTime = 9000;
      while(e != SUCCESS){
        e = configureAdc();
      }
      atomic TA1R = 0; //reset timer A
      call Timer0.startOneShot(maxTime);
      printf("Fib Iteration Num,ActualFrequency(Hz),Fib-startTime(ms),Fib-endTime(ms),currentMean(12bit),supplyMean(12bit),vcoreMean(12bit),adcStartTime(ms),adcEndTime(ms),app startTime(ms): %lu\n", call Timer0.gett0());
      post sweep();
  }
  
  event void Tasks.FibonacciDone(uint16_t iterations, uint32_t startTime, uint32_t endTime, error_t status){
    timeStart = startTime;
    timeEnd = endTime;
    atomic fibDone = TRUE;
    /*if(status ==SUCCESS)
      printf("tasks.fibDone; %lu\n", endTime-startTime);
    else
      printf("fib fail..\n");*/
  }
  
  event void Tasks.FibonacciIterationDone(){ }
  
  async event void overflow.conversionTimeOverflow(){ }

  async event void overflow.memOverflow(){ }
 
  async event void adc.dataReady(uint16_t *buffer, uint16_t numSamples){
    //printf("data ready: post\n");
    adcEndTime=call Timer2.getNow();
    //adcEndTime=call Timer0.getdt();
    call Timer2.stop();
    
    if(fibDone){
      post printadb();
      post sweep();
    }
    else
      post delaySweep();
  }
  
  event void Timer0.fired() {
    //printf("Timer0 fired! end time of program not valid! \n");
  }
  event void Timer1.fired() {
    bool ready;
    //printf("Timer1 Fired. Repost Sweep!\n");
    atomic ready = fibDone;
    if(ready){
      post printadb();
      post sweep();
    }
    else
      call Timer1.startOneShot(SWEEP_REPOST_DELAY);
  }
  event void Timer2.fired() {
    //printf("Timer2 fired! AdcConvertion endTime not valid!\n");
  }
  //functions

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
      e = call adc.configure(&adcconfig, adcchannelconfig, 2, adb, SAMPLES, 0);
    if(e != SUCCESS){
		showerror();
        printf("error %d\n", e);
    }
    return e;
  }
  
}
