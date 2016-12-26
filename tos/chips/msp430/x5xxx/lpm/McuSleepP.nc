/*
 * Copyright (c) 2011 Eric B. Decker
 * Copyright (c) 2009-2010 People Power Co.
 * Copyright (c) 2005 Stanford University. All rights reserved.
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
 */

/**
 * Implementation of TEP 112 (Microcontroller Power Management) for
 * the MSP430. Code for low power calculation copied from older
 * msp430hardware.h by Vlado Handziski, Joe Polastre, and Cory Sharp.
 *
 * Uses TI defines to identify which USCI resources are present.
 * Locate these by searching for HAS_T in the TI Code Composer Studio
 * header files in ccsv4/msp430/include.  MSPGCC and IAR should match
 * these definitions.
 *
 * @author Philip Levis
 * @author Vlado Handziski
 * @author Joe Polastre
 * @author Cory Sharp
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

module McuSleepP @safe() {
  provides {
    interface McuSleep;
    interface McuPowerState;
    interface McuSleepEvents;
  }
  uses {
    interface McuPowerOverride;
  }
}

implementation {

  /* Note that the power values are maintained in an order
   * based on their active components, NOT on their values.*/
  // NOTE: This table should be in progmem.
  // NOTE: On 5xx architectures, we assume SMCLKOFF is not set

  const uint16_t msp430PowerBits[MSP430_POWER_LPM4 + 1] = {
    0,                                       // ACTIVE
    SR_CPUOFF,                               // LPM0
    SR_SCG0+SR_CPUOFF,                       // LPM1
    SR_SCG1+SR_SCG0+SR_CPUOFF,               // LPM2
    SR_SCG1+SR_SCG0+SR_CPUOFF,               // LPM3
    SR_SCG1+SR_SCG0+SR_OSCOFF+SR_CPUOFF,     // LPM4
  };

  async command void McuSleep.sleep() {
    uint16_t temp;
    mcu_power_t power_state;

    power_state = call McuPowerOverride.lowestState();
    signal McuSleepEvents.preSleep(power_state);
    temp = msp430PowerBits[power_state] | SR_GIE;
    __asm__ __volatile__( "bis  %0, r2" : : "m" (temp) );
    // All of memory may change at this point...
    call McuSleep.irq_preamble();
    asm volatile ("" : : : "memory");
    __nesc_disable_interrupt();
    signal McuSleepEvents.postSleep(power_state);
  }

  async command void McuSleep.irq_preamble()  { }
  async command void McuSleep.irq_postamble() { }

  async command void McuPowerState.update () {
    // Do nothing; we always recalculate
  }

  default async command mcu_power_t McuPowerOverride.lowestState() {
    return MSP430_POWER_LPM4;
  }

  default async event void McuSleepEvents.preSleep(mcu_power_t sleep_mode)  { }
  default async event void McuSleepEvents.postSleep(mcu_power_t sleep_mode) { }
}
