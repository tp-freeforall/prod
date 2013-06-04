
/* Copyright (c) 2000-2003 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
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
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author Joe Polastre
 */

#include "Msp430Timer.h"

interface Msp430TimerControl {
  async command msp430_compare_control_t getControl();
  async command bool isInterruptPending();
  async command void clearPendingInterrupt();

  async command void setControl(msp430_compare_control_t control);

  /**
   * Sets the time in compare mode.
   *
   * setControlAsCompare has a predefined, hardcoded idea of
   * how the control register should be set for doing a compare.
   *
   * Your mileage may vary and this may not work for you.   In
   * which case you set use setControl.
   */
  async command void setControlAsCompare();
  
  /** 
  * Sets the timer in capture mode.
  *
  * It has a predefined idea of what mode that capture should occur in.
  * If that doesn't work for you, use setControl.
  *
  * @param cm configures the capture to occur on none, rising, falling or rising_and_falling edges
  * @param ccis configures which input channel to use.
  *
  * Msp430Timer.h has convenience definitions:
  *
  *     MSP430TIMER_CM_NONE,            MSP430TIMER_CCI_A
  *     MSP430TIMER_CM_RISING,          MSP430TIMER_CCI_B
  *     MSP430TIMER_CM_FALLING,         MSP430TIMER_CCI_GND
  *     MSP430TIMER_CM_BOTH             MSP430TIMER_CCI_VCC
  */ 
  async command void setControlAsCapture(uint8_t cm, uint8_t ccis);

  async command void enableEvents();
  async command void disableEvents();
  async command bool areEventsEnabled();
}
