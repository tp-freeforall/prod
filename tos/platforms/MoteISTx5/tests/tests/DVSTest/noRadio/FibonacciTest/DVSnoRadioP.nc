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
  uses interface Msp430Adc12SingleChannel as adc;
  uses interface Resource as AdcResource;
}
implementation {

  uint16_t adb[SAMPLES];
  //uint8_t count = 0;
  uint32_t Freq = 1000000;
  uint32_t ActFreq = 0;
  uint32_t EndFreq = 25000000; 
  uint32_t Step = 500000;
  uint32_t Time = 0;
  uint16_t Number = 0;
  bool AdcDone = FALSE;
  bool flag = 1;
    
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
  
  async command const msp430adc12_channel_config_t* AdcConfigure.getConfiguration(){
    return &adcconfig; // must not be changed
  }
  
  event void Boot.booted() {      
    //printf("Booted\n");
    call Leds.led0Off();
    call Leds.led1Off();
    call Leds.led2Off();
    P1DIR |= 0x40;                       // P1.6 to output direction
    P2DIR |= 0x01;                       // P2.0 to output direction
    P1SEL |= 0x40;                       // P1.6 Output SMCLK
    P2SEL |= 0x01;                       // 2.0 Output MCLK
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
      printf("Number#,Frequency(Hz),Time(ms),Vin(V),I(mA)\n");
      if(call FreqControl.setMCLKFreq(Freq) != SUCCESS)
				printf("Could not change the frequency to: %lu Hz. \r\n", Freq);
			else
				atomic ActFreq = Freq;
      
      call adc.getData();
        //printf("Conversion didn't start!\n");

      uwait(1024*5);
      atomic if(AdcDone){
        printadb();
        AdcDone=FALSE;
      }
      call Tasks.getFibonacci(ITERATIONS, DEADLINE);
  } 
  
  event void Tasks.FibonacciDone(uint16_t iterations, uint32_t elapsedTime, error_t status){
    printf("Task done in %lu ms\n",elapsedTime);
    atomic Time = elapsedTime;
    if(flag){
      flag=0;
      Freq=EndFreq;
      if(call FreqControl.setMCLKFreq(Freq) != SUCCESS)
				printf("Could not change the frequency to: %lu Hz. \r\n", Freq);
			else{
				//printf("MCLK frequency is now %lu Hz. \r\n\n", Freq);
        atomic ActFreq = Freq;
        atomic Number++; // increment the number of sequences calculated
      }
      call adc.getData();
      
      call Tasks.getFibonacci(ITERATIONS+100, DEADLINE);
      atomic if(AdcDone){
        printadb();
        AdcDone = FALSE;
      }
    }
  
    if(Freq==EndFreq){
      call Leds.led2On();
      return;
    }
  }
  
  event void Tasks.FibonacciIterationDone(){
  }
  
  async event void overflow.conversionTimeOverflow(){ }

  async event void overflow.memOverflow(){ }
 
  async event uint16_t *adc.multipleDataReady(uint16_t *buffer, uint16_t numSamples){
    AdcDone = TRUE;
    return buffer;
  }
  
  async event error_t adc.singleDataReady(uint16_t data){  
    return FAIL;
  }
  
//functions
 void printadb(){
    uint8_t i;
    float mean = 0;
    float Gain = 37.5; //(Gm*Rout)
    float refVolt = 2.5;
    float Nmax = 4095;
    float Vout = 0;
    float Current = 0;
    //float Vsense = 0;
    float Rsense = 1.01;
    
    for(i = 0; i < SAMPLES; i++){
      mean += (float) adb[i];
      //printf("Sample %d =", i);
      //printfFloat((float) adb[i]);
      //printf("\n");
      //printf("Vout =");
      //Vout = adb[i]*refVolt/Nmax;
      //Vout = ((float)((uint8_t)(Vout*100)))/100;
      //printfFloat(Vout);
      //printf(" V\n");
    }
      mean = mean/SAMPLES;
      //printf("Sample mean =");
      //printfFloat(mean);
      //printf("\n");
      
      //printf("Vout mean (into ADC) =");
      Vout = mean*refVolt/Nmax;
      //Vout = ((float)((uint8_t)(Vout*100)))/100;
      //printfFloat(Vout);
      //printf(" V\n");
      
      //Vsense = (Vout*1000)/Gain; //multiply by 1000 to get value in mV
     // printf("Vsense =");
     // printfFloat(Vsense);
     // printf(" mV\n");
      
      //Current = Vsense/Rsense; //current in mA, Rsense = 1.01 Ohm
      //printf("Current =");
      //printfFloat(Current);
      //printf(" mA\n");
      
      Current = (Vout*1000)/(Gain*Rsense); //current in mA, Rsense = 1.01 Ohm
      printf("%d,%lu,%lu,", Number, ActFreq, Time);
      printfFloat(Vout);
      printf(",");
      printfFloat(Current);
      //printf(" mA\n");
      //printf("\n");
      printf("\n");
  }


  void printfFloat(float toBePrinted) {
	uint32_t fi, f0, f1, f2;
	char c;
	float f = toBePrinted;

  	  if (f<0){
		c = '-'; f = -f;
		} else {
			c = ' ';
		}
		// integer portion.
		fi = (uint32_t) f;

		// decimal portion...get index for up to 3 decimal places.
		f = f - ((float) fi);
		f0 = f*10;   f0 %= 10;
		f1 = f*100;  f1 %= 10;
		f2 = f*1000; f2 %= 10;
		printf("%c%ld.%d%d%d", c, fi, (uint8_t) f0, (uint8_t) f1,  (uint8_t) f2);
  } 
  
  void showerror(){
    call Leds.led0On();
  }
  
  error_t configureAdc(){
    error_t e;
    //e = call adc.configureMultipleRepeat(&adcconfig, adb, SAMPLES, 0); 
    e = call adc.configureMultiple(&adcconfig, adb, SAMPLES, 0);
    if(e != SUCCESS){
		showerror();
        printf("error %d\n", e);
    }
    return e;
  }
  
}
