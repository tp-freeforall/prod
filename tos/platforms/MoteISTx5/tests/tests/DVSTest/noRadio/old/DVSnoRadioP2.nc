#include <stdio.h>
#include "Msp430Adc12.h"
#include "messagetypes.h"

#ifdef ADC12_TIMERA_ENABLED
#undef ADC12_TIMERA_ENABLED
#endif

#define ITERATIONS 900
#define DEADLINE 5000 // 5sec
#define SAMPLES 16
#define START_FREQUENCY 1000000  // 1MHz
#define STOP_FREQUENCY 25000000 // 25MHz
#define STEP_FREQUENCY 500000 // 500kHz

module DVSnoRadioP {
  provides interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfigure;
  uses interface Boot;
  uses interface Leds;
  uses interface Tasks;
  uses interface FreqControl;
  uses interface Msp430Adc12MultiChannel as adc;
  uses interface Resource as AdcResource;
  uses interface UartStream;
}
implementation {
 
  uint16_t adb[SAMPLES];
  uint32_t actualFreq = START_FREQUENCY;
  
  uartMessage message = {
    freq: START_FREQUENCY,
    time: 0,
    iter: 0,
    num: 0,
    current: 0,
    voltage: 0,
    lock: FALSE
  };
  
//prototypes
  void printfFloat(float toBePrinted);
  void showerror();
  error_t configureAdc();
  error_t readAdc();
  void uwait(uint32_t u);
  
  msp430adc12_channel_config_t adcconfig = {
    inch: INPUT_CHANNEL_A1,
    sref: REFERENCE_VREFplus_AVss,
    ref2_5v: REFVOLT_LEVEL_2_5,
    adc12ssel: SHT_SOURCE_ACLK,
    adc12div: SHT_CLOCK_DIV_1,
    sht: SAMPLE_HOLD_4_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
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
  
  task void sendMessage(){
    float Gain = 37.5; //(Gm*Rout)
    float refVolt = 2.5;
    float Nmax = 4095;
    float Vout = 0;
    float Rsense = 1.01;
    
    atomic{
    Vout = message.current * refVolt/Nmax;
    //Vout = ((float)((uint8_t)(Vout*100)))/100;
    //Vsense = (Vout*1000)/Gain; //multiply by 1000 to get value in mV
    
    message.current = (Vout*1000)/(Gain*Rsense); //current in mA, Rsense = 1.01 Ohm
    //printf("%d,%lu,%lu,", Number, ActFreq, Time);
    message.voltage *= (refVolt*2)/Nmax; //multiply by 2 to get the real batery value
    
    printf("%lu,%lu,%d,%d,", message.freq, message.time, message.iter, message.num);
    printfFloat(message.current);
    printf(",");
    printfFloat(message.voltage);
    printf("\n");
    message.lock=FALSE;
    }
  }
  
  event void Boot.booted() {      
    printf("Booted\n");
  //  P1DIR |= 0x40;                       // P1.6 to output direction
  //  P2DIR |= 0x01;                       // P2.0 to output direction
  //  P1SEL |= 0x40;                       // P1.6 Output SMCLK
  //  P2SEL |= 0x01;                       // 2.0 Output MCLK
    //request the adc
    call AdcResource.request();
  }
  
  event void AdcResource.granted(){
    error_t e = FAIL;
      while(e != SUCCESS){
        e = configureAdc();
      }
      /*
       * Set start frequency
       */
      if(call FreqControl.setMCLKFreq(START_FREQUENCY) != SUCCESS){
        printf("error: set start frequency\n");
        showerror();
        return;
      }
      /*
       * Read first data
       */
      readAdc();
      
      //Start the First Fibonacci running at START_FREQUENCY
      if(call Tasks.getFibonacci(ITERATIONS,DEADLINE) != SUCCESS){
        printf("error: first fib\n");
        showerror();
      return;
      }
  }
  
  event void Tasks.FibonacciDone(uint16_t iterations, uint32_t elapsedTime, error_t status){
    bool lock;
    printf("fib done: elapsed %lu\n", elapsedTime);
    if(status!=SUCCESS){
      printf("error: did not finish fib\nelapsed %lu\n", elapsedTime);
      showerror();
      return;
    }
    printf("wait adc 1\n");
    while(lock){ atomic lock = message.lock; } //wait for any adc convertion to finish
    
    atomic message.time = elapsedTime;
    readAdc();
    
    if(actualFreq==STOP_FREQUENCY){
      /*
       * Finished, light green led
       */
      call Leds.led2On();
      return;
    }
    if(START_FREQUENCY < STOP_FREQUENCY)
      actualFreq += STEP_FREQUENCY;
    else
      actualFreq -= STEP_FREQUENCY;
      
    printf("wait adc 2\n");
    while(lock){ atomic lock = message.lock; } //wait for any adc convertion to finish
    atomic message.num++;
    atomic message.freq = actualFreq;

    if(call FreqControl.setMCLKFreq(actualFreq) != SUCCESS){
      showerror();
      atomic printf("error: in fibDone %d\n", message.num);
      return;
    }
    
    if(call Tasks.getFibonacci(ITERATIONS,DEADLINE) != SUCCESS){
      showerror();
      return;
    }
    
  }
  
  event void Tasks.FibonacciIterationDone(uint16_t iter){ }
  
  async event void adc.dataReady(uint16_t *buffer, uint16_t numSamples){
    uint8_t i;
    uint32_t current, voltage;
    for(i = 0; i<(numSamples/2); i++){
      current += buffer[i];
      voltage += buffer[i+1];
    }
    message.current = (float) current/(numSamples/2);
    message.voltage = (float) voltage/(numSamples/2);
    post sendMessage();
  }
  
  async event void UartStream.sendDone(uint8_t* buf, uint16_t len, error_t err){ }
  async event void UartStream.receivedByte (uint8_t byte) { }
  async event void UartStream.receiveDone (uint8_t* buf, uint16_t len, error_t err) { }
  
//functions

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
      e = call adc.configure(&adcconfig, &channelconfig, 1, adb, SAMPLES, 0);
    if(e != SUCCESS){
      showerror();
      printf("error %d\n", e);
    }
    return e;
  }
  
  error_t readAdc(){
    atomic message.lock=TRUE;
    return call adc.getData();
  }
  
  void uwait(uint32_t u) {
    uint32_t t0 = TA0R;
    while((TA0R - t0) <= u);
  }
}
