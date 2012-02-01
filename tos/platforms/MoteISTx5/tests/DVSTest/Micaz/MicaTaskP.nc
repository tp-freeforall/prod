#include <Timer.h>
#include "../RadioAdc/Radio.h"

module MicaTaskP {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
}
implementation {
  
  message_t pkt;
  bool busy = FALSE;
  bool up = TRUE;
  uint16_t missedDeadlines = 0;
  uint16_t metDeadlines = 0;
  uint16_t deadline = 100; //now using this one instead of the one in radio.h
  uint16_t iterations = 100; //now using this one instead of the one in radio.h
  uint16_t numRequest = 0; //serves as a counter for rasing or lowering the iteration number
  uint16_t requestNum = 0;//count the number of requests so far
  //prototypes
  error_t MicaSendMsg(uint8_t state);
  
  event void Boot.booted() {
    call AMControl.start(); //start radio
  }
  
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call Timer1.startPeriodic(PERIOD);
    }
    else {
      call AMControl.start();
    }
  }
  
    event void AMControl.stopDone(error_t err) {
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
      busy = FALSE;		
		}
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    MoteISTMsg* mist_m;
    MicaMsg* micaz_m;
   
    if (len == sizeof(MoteISTMsg)) {
      mist_m = (MoteISTMsg*)payload;
      if(mist_m->nodeid == MOTEIST_NODE_ID){
				if (!busy) { //check if radio is busy
          micaz_m = (MicaMsg*)(call Packet.getPayload(&pkt, sizeof(MicaMsg)));
          if (micaz_m == NULL){
						return 0;
          }
          micaz_m->nodeid = MICA_NODE_ID; //assign Micaz ID
          micaz_m->task_i = iterations;
					micaz_m->deadline = deadline;
					micaz_m->missed = missedDeadlines;
          micaz_m->met = metDeadlines;
					
          switch (mist_m->state){
            case REQUEST: // MoteIST ready for start
              micaz_m->state = START;
              break;
            case STARTED: // MoteIST has started
              call Timer0.startOneShot(deadline);
              return msg; // At this point don't need to send msg to MoteIST, return
            case DEADLINE_MET:
              call Timer0.stop(); //stop timer, deadline is met
              call Leds.led1Toggle();
              micaz_m->met = ++metDeadlines;
              micaz_m->state = DEADLINE_MET;
              break;
            case DEADLINE_MISS: // MoteIST missed the deadline, too bad.. but nothing to do here
              return msg;
						default:
          }	
          if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MicaMsg)) == SUCCESS) {
						busy = TRUE;
					}
        }//if !busy
			}// if == MICA_NODE_ID
    }// if len = len MicaMsg
    return msg;
  }
  
      
  
  event void Timer0.fired(){ //deadline Reached
    missedDeadlines++;
    call Leds.led0Toggle();
    MicaSendMsg(DEADLINE_MISS);
  }
  
  event void Timer1.fired(){ //make new request
    requestNum++;
    MicaSendMsg(REQUEST);
    numRequest++;
    
    if(numRequest>3){
      switch(up){
        case TRUE:
          if(iterations < ITERATIONS)
            iterations += 200;
          else{
            up = FALSE;
            return;
          }
          break;
        case FALSE:
          if(iterations > 200)
            iterations -= 200;
          else{
            call Timer1.stop();
            return;
          }
          break;
        default:
      }
      numRequest=0;
    }
	}
  
  //functions
  error_t MicaSendMsg(uint8_t state){
    
    MicaMsg* micaz_m;
		if (!busy) { //check if radio is busy
      micaz_m = (MicaMsg*)(call Packet.getPayload(&pkt, sizeof(MicaMsg)));
      if (micaz_m == NULL){
				return FAIL;
      }
			micaz_m->nodeid = MICA_NODE_ID;
      micaz_m->request = requestNum;
			micaz_m->task_i = iterations; // 0 for deadline miss
			micaz_m->deadline = deadline;
			micaz_m->missed = missedDeadlines;
			micaz_m->met = metDeadlines;
			micaz_m->state = state;
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(MicaMsg)) == SUCCESS) {
				busy = TRUE;
      }
    }
    return SUCCESS;
  }
  
}
