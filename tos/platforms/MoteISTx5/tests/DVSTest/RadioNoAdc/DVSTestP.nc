#include <Timer.h>
#include <stdio.h>
#include "Radio.h"

#define MAX_FREQUENCY_INCREASE 5000000
#define MAX_FREQUENCY 25000000
#define START_FREQUENCY 25000000

module DVSTestP {
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
}
implementation {
  
  message_t pkt;
  bool busy = FALSE;
  uint16_t state;
  uint32_t ActFrequency = 0;
  uint16_t deadline;
  // prototypes  
  error_t SendMsgTaskDone();
  error_t AdaptFrequency(uint32_t elapsedTime, error_t taskStatus);
  
  event void Boot.booted() {
    printf("Booted\n");
    P1DIR |= 0x40;                       // P1.6 to output direction
    P2DIR |= 0x01;                       // P2.0 to output direction
    P1SEL |= 0x40;                       // P1.6 Output SMCLK
    P2SEL |= 0x01;                       // 2.0 Output MCLK
    if(call FreqControl.setMCLKFreq(START_FREQUENCY) == SUCCESS){
      ActFrequency = START_FREQUENCY;
      printf("Frequency at %lu Hz\n", ActFrequency);
      call AMControl.start(); //start radio
    }
    else
      printf("err: Could not set Start Frequency\n");
  }
  
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) { printf("Radio started\n");}
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
              printf("Mica: REQUEST\n\n");
              mist_m->state = REQUEST;
              state = REQUEST;
              break;
            case START:
              printf("Mica: START.\niterations=%d\ndeadline=%d\nmissed=%d\nmet=%d\n\n", micaz_m->task_i, micaz_m->deadline, micaz_m->missed, micaz_m->met);
              mist_m->state = STARTED;
              call Tasks.getFibonacci(micaz_m->task_i, micaz_m->deadline);
              state = STARTED;
              deadline = micaz_m->deadline;
              break;
            case DEADLINE_MET:
              call Leds.led2Toggle();
              printf("Mica DEADLINE_MET:\nmissed=%d\nmet=%d\n\n", micaz_m->missed, micaz_m->met);
              return msg;
              break;
            case DEADLINE_MISS:
              call Leds.led1Toggle();
              printf("Mica: DEADLINE_MISS:\nmissed=%d\nmet=%d\n\n", micaz_m->missed, micaz_m->met);
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
    if(status == SUCCESS)
      if(SendMsgTaskDone()!=SUCCESS)
        call Timer0.startPeriodic(1);
    AdaptFrequency(elapsedTime, status);
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
    printf("Task done! Elapsed: %lu, status: %d\n", elapsedTime, taskStatus);
    printf("Act Freq is %lu Hz\n", ActFrequency);
    
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
    printf("New Freq is %lu Hz\n", ActFrequency);
    return SUCCESS;
  }
}
