#include "hardware.h"

module PlatformP{
  provides interface Init;
  provides interface Platform;
  uses interface Init as Msp430ClockInit;
  uses interface Init as LedsInit;
}
implementation {
  command error_t Init.init() {
    call Msp430ClockInit.init();
    TOSH_SET_PIN_DIRECTIONS();
    call LedsInit.init();
    return SUCCESS;
  }

  async command uint32_t Platform.localTime()      { return 0; }
  async command uint32_t Platform.usecsRaw()       { return 0; }
  async command uint32_t Platform.usecsRawSize()   { return 0; }
  async command uint32_t Platform.jiffiesRaw()     { return 0; }
  async command uint32_t Platform.jiffiesRawSize() { return 0; }
  async command bool     Platform.set_unaligned_traps(bool on_off) {
    return FALSE;
  }
  async command int      Platform.getIntPriority(int irq_number) {
    return 0;
  }

  default command error_t LedsInit.init() { return SUCCESS; }
}

