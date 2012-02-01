#include <Timer.h>
#include <stdio.h>
#include "Radio.h"

#define ADC_SAMPLE_TIME 10 //miliseconds

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
}
implementation {
  
  message_t pkt;
  bool busy = FALSE;
  uint16_t state;
 
  // prototypes  
  error_t SendMsgTaskDone();
  
  
  event void Boot.booted() {
    //call Timer0.startPeriodic(ADC_SAMPLE_TIME);
    printf("Booted\n");
    call Leds.led0Off();
    call Leds.led1Off();
    call Leds.led2Off();
    call AMControl.start(); //start radio
  }
  
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {}
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
              printf("Mica: START. \niterations=%d\ndeadline=%d\nmissed=%d\nmet=%d\n\n", micaz_m->task_i, micaz_m->deadline, micaz_m->missed, micaz_m->met);
              mist_m->state = STARTED;
              call Tasks.getFibonacci(micaz_m->task_i, micaz_m->deadline);
              state = STARTED;
              break;
            case DEADLINE_MET:
              call Leds.led2Toggle();
              printf("Mica DEADLINE_MET:\nmissed=%d\nmet=%d\n\n", micaz_m->missed, micaz_m->met);
              return msg;
              break;
            case DEADLINE_MISS:
              call Leds.led1Toggle();
              printf("Mica: DEADLINE_MISS\nmissed=%d\nmet=%d\n\n", micaz_m->missed, micaz_m->met);
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
    if(SendMsgTaskDone()!=SUCCESS)
      call Timer0.startPeriodic(1);
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
}
