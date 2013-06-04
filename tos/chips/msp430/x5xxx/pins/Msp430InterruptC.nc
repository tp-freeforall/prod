/*
 * Copyright (c) 2013 Eric B. Decker
 * Copyright (c) 2000-2005 The Regents of the University of California.  
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
 * - Neither the name of the copyright holder nor the names of
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
 * Implementation of the GPIO interrupt abstraction for
 * the TI MSP430 microcontroller.   X5 processors
 *
 * The X5 processors clear the highest IFG automatically when the IV
 * has been read.   While the X1/X2 processors don't do this.   This
 * means the interrupt handler on the X1/X2 puppies have to do it
 * themselves.  Hence different files.
 *
 * @author Jonathan Hui
 * @author Joe Polastre
 * @author Eric B. Decker <cire831@gmail.com>
 * @see  Please refer to TEP 117 for more information about this component and its
 *          intended use.
 */

generic module Msp430InterruptC() @safe() {
  provides interface GpioInterrupt as Interrupt;
  uses interface HplMsp430Interrupt as HplInterrupt;
}

implementation {
  async command error_t Interrupt.enableRisingEdge() {
    atomic {
      call Interrupt.disable();
      call HplInterrupt.clear();
      call HplInterrupt.edgeRising();
      call HplInterrupt.enable();
    }
    return SUCCESS;
  }

  async command error_t Interrupt.enableFallingEdge() {
    atomic {
      call Interrupt.disable();
      call HplInterrupt.clear();
      call HplInterrupt.edgeFalling();
      call HplInterrupt.enable();
    }
    return SUCCESS;
  }

  async command error_t Interrupt.disable() {
    call HplInterrupt.disable();

    /*
     * formerly, this also cleared out any pending interrupt that came in after the disable too.
     * If it came in prior to the disable, it would have interrupted us and been handled.
     *
     * So there is a window between the disable happening and the clear happening where an
     * event will get thrown away.   This is bad.   It is better to simply let the disable
     * happen and maybe later decide if we are shutting down the system or not.  If not
     * we may very well want to see the event.
     */
    return SUCCESS;
  }

  async event void HplInterrupt.fired() {
    /*
     * The X5 h/w clears the highest pending interrupt flag (IFG) when
     * the IV is accessed (read or written, go figure).  In other words the
     * h/w has already cleared the interrupt.
     *
     * Don't do it again or we could potentially throw away yet another
     * event.  Bad bad bad.
     *
     * There used to be a clear here that the x1/x2 processors need.  But x5
     * processors don't.
     */
    signal Interrupt.fired();
  }
}
