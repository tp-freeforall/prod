#include <Timer.h>
#include <stdio.h>
#include "Radio.h"
#include "Msp430Adc12.h"


#ifdef ADC12_TIMERA_ENABLED
#undef ADC12_TIMERA_ENABLED
#endif
#define MAX_FREQUENCY_INCREASE 5000000
#define MAX_FREQUENCY 25000000
#define START_FREQUENCY 25000000
#define SAMPLES 16

module RadioAdcP {
  provides interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfigure;
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  uses interface Tasks;
  
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
  uses interface FreqControl;
  uses interface Msp430Adc12MultiChannel as adc;
  uses interface Resource as AdcResource;
}
implementation {
  
  message_t pkt;
  bool busy = FALSE;
  uint16_t state;
  uint32_t ActFrequency = 0;
  uint16_t deadline;
  uint16_t requestNum;

  uint16_t adb[SAMPLES];
  bool AdcDone = FALSE;
    
  //prototypes
  void print(uint16_t iterations, uint32_t elapsedTime, error_t status);
  void showerror();
  error_t configureAdc();

  error_t SendMsgTaskDone();
  error_t AdaptFrequency(uint32_t elapsedTime, error_t taskStatus);
  void uwait(uint32_t u);
  void printfFloat(float toBePrinted);
  
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
    printf("Iterations,Deadline,Frequency,ElapsedTime,Current,Voltage,Status\n");
    
    if(call FreqControl.setMCLKFreq(START_FREQUENCY) == SUCCESS){
      ActFrequency = START_FREQUENCY;
      //printf("Frequency at %lu Hz\n", ActFrequency);
        //request the adc
      call AdcResource.request();
    }
    else
      printf("err: Could not set Start Frequency\n");
  }
  
  event void AdcResource.granted(){
    error_t e = FAIL;
      while(e != SUCCESS){
        e = configureAdc();
      }
      call adc.getData();
      uwait(1024*5);
      atomic if(AdcDone){
        print(0, 0, 0);
        AdcDone=FALSE;
      }
    call AMControl.start(); //start radio
  }
  
  async event void adc.dataReady(uint16_t *buffer, uint16_t numSamples){
    AdcDone = TRUE;
  }
  
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) { /*printf("Radio started\n");*/}
    else 
      call AMControl.start();
  }
  
    event void AMControl.stopDone(error_t err) {
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg)
      busy = FALSE;
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    MoteISTMsg* mist_m;
    MicaMsg* micaz_m;

    if (len == sizeof(MicaMsg)) {
      micaz_m = (MicaMsg*)payload;
      /*
       * Check if message comes from Mica1 and if it is a request to start the processing (task != 0)
       */
      if(micaz_m->nodeid == MICA_NODE_ID){
				//printf("Incoming msg from mica\n");
				if (!busy) { //check if radio is busy
          mist_m = (MoteISTMsg*)(call Packet.getPayload(&pkt, sizeof(MoteISTMsg)));
          if (mist_m == NULL){
	        return 0;
          }
          mist_m->nodeid = MOTEIST_NODE_ID; //assign MoteIST ID
          state = micaz_m->state;
          switch(micaz_m->state){
            
            case REQUEST:
              //printf("Mica: REQUEST\n\n");
              mist_m->state = REQUEST;
              state = REQUEST;
              break;
            case START:
              //printf("Mica: START.\niterations=%d\ndeadline=%d\nmissed=%d\nmet=%d\n\n", micaz_m->task_i, micaz_m->deadline, micaz_m->missed, micaz_m->met);
              mist_m->state = STARTED;
              call Tasks.getFibonacci(micaz_m->task_i, micaz_m->deadline);
              requestNum = micaz_m->request;
              deadline = micaz_m->deadline;
              break;
            case DEADLINE_MET:
              call Leds.led2Toggle();
              //printf("Mica DEADLINE_MET:\nmissed=%d\nmet=%d\n\n", micaz_m->missed, micaz_m->met);
              return msg;
              break;
            case DEADLINE_MISS:
              call Leds.led1Toggle();
              //printf("Mica: DEADLINE_MISS:\nmissed=%d\nmet=%d\n\n", micaz_m->missed, micaz_m->met);
              return msg;
              break;
            default:
              break;
					}
          if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MoteISTMsg)) == SUCCESS) {
            busy = TRUE;
          }
        }//if !busy
			}// if == MICA_NODE_ID
    }// if len = len MicaMsg
    return msg;
  }
  
  event void Tasks.FibonacciDone(uint16_t iterations, uint32_t elapsedTime, error_t status){
    call adc.getData();
    
    if(status == SUCCESS)
      if(SendMsgTaskDone()!=SUCCESS)
        call Timer0.startPeriodic(1);
    
    AdaptFrequency(elapsedTime, status);
    
    atomic if(AdcDone){
        print(iterations, elapsedTime, status);
        AdcDone=FALSE;
      }
  }
  event void Tasks.FibonacciIterationDone(){ }
  
  event void Timer0.fired() {
    if(SendMsgTaskDone()==SUCCESS)
      call Timer0.stop();
  }
  
  event void Timer1.fired() {}
  
  
  //functions
  error_t SendMsgTaskDone(){
    MoteISTMsg* mist_m;
    if (!busy) {//check if radio is busy
      /*build the packet*/
      mist_m = (MoteISTMsg*)(call Packet.getPayload(&pkt, sizeof(MoteISTMsg)));
      if (mist_m == NULL){
        printf("App: null pointer\n");
	      return FAIL;
      }
      mist_m->state = DEADLINE_MET; // task done in time
      state = DEADLINE_MET;
      /*send the packet*/
      if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MoteISTMsg)) == SUCCESS){
        busy = TRUE;
      }
      return SUCCESS;
    } //if(!busy)
  return FAIL;
  }
  
  error_t AdaptFrequency(uint32_t elapsedTime, error_t taskStatus){
    uint32_t newFreq;
    float deadlineWindow;
    deadlineWindow = deadline - deadline * 0.5;
    //printf("Task done! Elapsed: %lu, status: %d\n", elapsedTime, taskStatus);
    //printf("Act Freq is %lu Hz\n", ActFrequency);
    
    if(taskStatus!=SUCCESS)
      newFreq = ActFrequency + MAX_FREQUENCY_INCREASE;
    else{
      //ajust to finish in 20% less time of deadline
      newFreq = (uint32_t) ( (((float) elapsedTime) / deadlineWindow) * ((float) ActFrequency) );
      newFreq = (newFreq/100000)*100000; //round frequency to hundreads of kHz
    }
    if(newFreq == ActFrequency || newFreq < 700000)
        return FAIL;
    
    if(newFreq > MAX_FREQUENCY)
      newFreq = MAX_FREQUENCY;
        
    if(call FreqControl.setMCLKFreq(newFreq)==SUCCESS)
      ActFrequency = newFreq;
    //set new frequency to the one needed in order to meet the deadline in half its time with a 20% window
    //printf("New Freq is %lu Hz\n", ActFrequency);
    return SUCCESS;
  }
  
  void print(uint16_t iterations, uint32_t elapsedTime, error_t status){
    uint8_t i;
    float currentMean = 0;
    float voltageMean = 0;
    float Gain = 37.5; //(Gm*Rout)
    float refVolt = 2.5;
    float Nmax = 4095;
    float Rsense = 1.01;
    
    for(i = 0; i < SAMPLES; i+=2){
      currentMean += (float) adb[i];
      voltageMean += (float) adb[i+1];
    }
      currentMean /= SAMPLES/2;  //bits
      voltageMean /= SAMPLES/2; // bits
      currentMean *= refVolt/Nmax; //value in Volts
      voltageMean *= refVolt/Nmax; //value in Volts
      
      currentMean = (currentMean*1000)/(Gain*Rsense); //current in mA, Rsense = 1.01 Ohm
      //voltageMean *= 2; // multiply by 2.92 to get total battery voltage
      
      printf("%d,%d,%d,%lu,%lu,%d,", requestNum, iterations, deadline, ActFrequency, elapsedTime, status);
      printfFloat(currentMean);
      printf(",");
      printfFloat(voltageMean);
      printf("\n");
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
  
  void uwait(uint32_t u) {
    uint32_t t0 = TA0R;
    while((TA0R - t0) <= u);
  }
}
