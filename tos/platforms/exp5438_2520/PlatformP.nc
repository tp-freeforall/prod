/*
 * Copyright (c) 2010-2011, 2013-2014, 2017-2018 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Warning: many of these routines directly touch cpu registers
 * it is assumed that this is initilization code and interrupts are
 * off.
 *
 * @author Eric B. Decker
 */

#include "hardware.h"
#include "platform_version.h"
#include "panic.h"
#include "cpu_stack.h"

const uint8_t  _major = MAJOR;
const uint8_t  _minor = MINOR;
const uint16_t _build = _BUILD;


#define BOOT_MAJIK 0x01021910
noinit uint32_t boot_majik;
noinit uint16_t boot_count;
noinit uint16_t stack_size;


extern uint16_t _etext, _end;
static void PanicP__Panic__panic(uint8_t pcode, uint8_t where, parg_t arg0,
                                 parg_t arg1, parg_t arg2, parg_t arg3);

void check_weeds(void * chk) {
  register void *sp asm("r1");
    uint16_t *p = &_end;

  if (chk > (void *) &_etext) {
    PanicP__Panic__panic(PANIC_KERN, 0xff, (parg_t) sp, (parg_t) chk, (parg_t) &_etext, 0);
  }
  if (chk < (void *) 0x5c00) {
    PanicP__Panic__panic(PANIC_KERN, 0xef, (parg_t) sp, (parg_t) chk, (parg_t) 0x5c00, 0);
  }
  if (*p != STACK_GUARD) {
    PanicP__Panic__panic(PANIC_KERN, 0xfd, (parg_t) sp, *p, 0, 0);
  }
}


module PlatformP {
  provides {
    interface Init;
    interface Platform;
    interface BootParams;
  }
  uses {
    interface Init as PlatformPins;
    interface Init as PlatformLeds;
    interface Init as PlatformClock;
    interface Init as MoteInit;
    interface Init as PeripheralInit;
    interface LocalTime<TMilli>;
    interface Stack;
  }
}

implementation {

/*
 * See PlatformClockP.nc for assignments
 */

#define USEC_REG    TA0R
#define JIFFIES_REG TA1R

  void uwait(uint16_t u) {
    uint16_t t0 = USEC_REG;
    while((USEC_REG - t0) <= u);
  }

  command error_t Init.init() {
    WDTCTL = WDTPW + WDTHOLD;    // Stop watchdog timer

    call PlatformPins.init();   // Initializes the GIO pins

    /*
     * check to see if memory is okay.   The boot_majik cell tells the story.
     * If it isn't okay we lost RAM, reinitilize boot_count.
     */

    if (boot_majik != BOOT_MAJIK) {
      boot_majik = BOOT_MAJIK;
      boot_count = 0;
    }
    boot_count++;

    call Stack.init();
    stack_size = call Stack.size();

    call PlatformLeds.init();   // Initializes the Leds
    call PlatformClock.init();  // Initializes UCS
    call PeripheralInit.init();
    return SUCCESS;
  }

  async command uint16_t BootParams.getBootCount() {
    return boot_count;
  }


  async command uint8_t BootParams.getMajor() {
    return _major;
  }


  async command uint8_t BootParams.getMinor() {
    return _minor;
  }


  async command uint16_t BootParams.getBuild() {
    return _build;
  }


  async command uint32_t Platform.localTime()      { return call LocalTime.get(); }
  async command uint32_t Platform.usecsRaw()       { return USEC_REG; }
  async command uint32_t Platform.usecsRawSize()   { return 16; }
  async command uint32_t Platform.jiffiesRaw()     { return JIFFIES_REG; }
  async command uint32_t Platform.jiffiesRawSize() { return 16; }

  async command bool     Platform.set_unaligned_traps(bool set_on) {
    return FALSE;
  }
  async command int      Platform.getIntPriority(int irq_number) {
    return 0;
  }


  /***************** Defaults ***************/
  default command error_t PeripheralInit.init() {
    return SUCCESS;
  }
}
