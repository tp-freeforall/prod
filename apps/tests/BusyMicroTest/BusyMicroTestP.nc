
#include "printfZ1.h"

module BusyMicroTestP @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Timer<TMilli>;
    interface BusyWait<TMicro, uint16_t>;
    interface GeneralIO as SCLK;
  }
}
implementation {
  event void Boot.booted() {
    printfz1_init();
//  call Timer.startPeriodic(4096);
    call Leds.led1Toggle();

    printfz1("booted\n");

    call SCLK.makeOutput();
    while (1) {
      call Leds.led2Toggle();
      call SCLK.toggle();
      call BusyWait.wait(1);
    }
  }

  event void Timer.fired() {
  }
}
