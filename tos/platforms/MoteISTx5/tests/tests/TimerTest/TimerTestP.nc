
#include <Timer.h>
#include <stdio.h>
#define DEADLINE 100

module TimerTestP {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
}
implementation {
   
  void uwait(uint16_t u) {
    uint16_t t0 = TA0R;
    while((TA0R - t0) <= u);
  }
  

  event void Boot.booted() {
    P6SEL &= 0xFB; //ADC2 sel GIO func
    P6DIR |= 0x04; //ADC2 sel output func
    P6OUT &= 0xFB; //ADC output 0
    uwait(1000);
    P6OUT |= 0x04; //ADC output 1 //start pulse
    uwait(1000);
    P6OUT &= 0xFB; //ADC output 0
    uwait(1000);
    P6OUT |= 0x04; //ADC output 1 //start pulse
    call Timer0.startPeriodic(DEADLINE); 
  }
  
  event void Timer0.fired() {
	uint32_t time;
	P6OUT &= 0xFB; //ADC output 0
//	P6OUT |= 0x04; //ADC output 1 //end pulse
    //time = call Timer0.getNow();
    //printf("Timer fired at %lu \n", time);
  }
}
