/*
 * Copyright (c) 2013, Eric B. Decker
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
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * The default for GpioCapture is CCIxA.  Other channels are available
 * (like B) but they need to be hardcoded in another module.  See
 * tos/platforms/exp5438_2520/hardware/cc2520/P81SfdCaptureC.nc
 *
 * Lower levels have been modified to support being able to change
 * CCIS in the control registers.
 *
 * X2 and X5 chips have an IV register.   When the IV (interrupt
 * vector) register is read it clears the highest pending interrupt
 * flag as well.   Code that handles these interrupts used to
 * clear the IFG explicitly.   Doing so creates a race condition
 * where new interrupts occuring in the tiny window prior the this
 * clearing of the IFG would cause a lost interrupt.
 *
 * This version of GpioCapture does not clear the IFG but rather relies
 * on the h/w clearing done by reading the IV.
 *
 * This version of GpioCapture uses GenericCapture which provides a modified
 * interface which exports capture overflow.
 */

#include "Msp430Timer.h"

generic module GpioCaptureC() @safe() {
  provides interface GenericCapture<uint16_t> as GCap;
  uses {
    interface Msp430TimerControl;
    interface Msp430CaptureV2      as MCap2;
    interface HplMsp430GeneralIO   as CaptureBit;
  }
}

implementation {

  typedef msp430_compare_control_t cc_t;

  DEFINE_UNION_CAST(int2CC,cc_t,uint16_t)

  error_t enableCapture( uint8_t mode ) {
    atomic {
      /*
       * reset TxCCTLx to 0, clears all important control bits
       * CM 0 (no capture), gets changed later, CCIS (CCIxA), SCS sync,
       * CAP 0 (compare), CCIE 0, COV 0, CCIFG 0
       *
       * equivalent to:  (but more efficient)
       *
       *     disableEvents();
       *     clearPendingInterrupt();
       *     clearOverflow();
       */
      call Msp430TimerControl.setControl(int2CC(0));
      call CaptureBit.makeInput();                               /* for capture to work must be input */
      call CaptureBit.selectModuleFunc();                        /* and must be assigned to the Module */

      /* Default setting for CCIS is channel A. */
      call Msp430TimerControl.setControlAsCapture( mode, MSP430TIMER_CCI_A );

      /* while debugging, being async makes it so we can see the SFD signal */
      call MCap2.setSynchronous(FALSE);
    }
    return SUCCESS;
  }

  async command error_t GCap.captureRisingEdge() {
    return enableCapture(MSP430TIMER_CM_RISING);
  }

  async command error_t GCap.captureFallingEdge() {
    return enableCapture(MSP430TIMER_CM_FALLING);
  }

  async command error_t GCap.captureBothEdges() {
    return enableCapture(MSP430TIMER_CM_BOTH);
  }

  async command void    GCap.setRisingEdge() {
    call MCap2.setEdge(MSP430TIMER_CM_RISING);
  }
  
  async command void    GCap.setFallingEdge() {
    call MCap2.setEdge(MSP430TIMER_CM_FALLING);
  }

  async command void    GCap.setBothEdges() {
    call MCap2.setEdge(MSP430TIMER_CM_BOTH);
  }

  async event void MCap2.captured(uint16_t time, bool overflow) {
    /*
     * do not clear the interrupt here.  The h/w on the X2 and
     * the x5 has already done it.  (the read of the IV did it)
     *
     * Do not clear out overflow.  Seperate interface for seeing
     * overfow and controlling it.
     */
    signal GCap.captured(time, overflow);
  }

  async command void GCap.disable() {
    call Msp430TimerControl.disableEvents();
    call CaptureBit.selectIOFunc();
  }

  async command void GCap.clearInterrupt() {
    call Msp430TimerControl.clearPendingInterrupt();
  }

  async command void GCap.enableInterrupt() {
    call Msp430TimerControl.enableEvents();
  }

  async command void GCap.disableInterrupt() {
    call Msp430TimerControl.disableEvents();
  }

  async command bool GCap.overflowed() {
    return call MCap2.isOverflowPending();
  }

  async command void GCap.clearOverflow() {
    call MCap2.clearOverflow();
  }

  async command bool     GCap.test() {
    return call Msp430TimerControl.isInterruptPending();
  }
  
  async command uint16_t GCap.get() {
    return call MCap2.getEvent();
  }
}
