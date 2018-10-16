#include "hardware.h"

module PlatformP @safe() {
  provides interface Init;
  provides interface Platform;
  uses {
    interface GeneralIO as OrangeLedPin;
    interface Init as LedsInit;
    interface Init as McuInit;
  }
}

implementation {
  command error_t Init.init() {
    error_t ok;

    ok = call McuInit.init();
    ok = ecombine(ok, call LedsInit.init());
    return ok;
  }

  default command error_t McuInit.init() {
    return SUCCESS;
  }

  default command error_t LedsInit.init() {
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
}
