/**
 **/

#include "Timer.h"

uint16_t start_xt1;
uint16_t start_dco;
uint16_t upper;

module ClockP @safe() {
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  uses interface Timer<TMilli> as Timer2;
  uses interface Leds;
  uses interface Boot;
}
implementation {
  event void Boot.booted() {

    dint();
    upper = 0;
    TA0R = 0;
    TA0CTL &= ~TAIFG;

#ifdef notdef
    while (1) {
      if (TA0CTL & TAIFG) {
	upper++;
	if (upper >= 30)
	  break;
	TA0CTL &= ~TAIFG;
      }
    }
#endif

    TA0CCR0 = 1024;
    TA0CCTL0 = 0;
    TA0R = 0;
    TA1R = 0;
    while (1) {
      if (TA0CCTL0 & CCIFG) {
	upper = TA1R;
	nop();
	break;
      }
    }

    call Timer0.startPeriodic( 250 );
    call Timer1.startPeriodic( 500 );
    call Timer2.startPeriodic( 1000 );
  }

  event void Timer0.fired() {
    dbg("BlinkC", "Timer 0 fired @ %s.\n", sim_time_string());
    call Leds.led0Toggle();
    nop();
  }
  
  event void Timer1.fired() {
    dbg("BlinkC", "Timer 1 fired @ %s \n", sim_time_string());
    call Leds.led1Toggle();
    nop();
  }
  
  event void Timer2.fired() {
    dbg("BlinkC", "Timer 2 fired @ %s.\n", sim_time_string());
    call Leds.led2Toggle();
    nop();
  }
}
