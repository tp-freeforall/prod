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
 * the TI MSP430 microcontroller.
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
      call HplInterrupt.edgeRising();
      call HplInterrupt.enable();
    }
    return SUCCESS;
  }

  async command error_t Interrupt.enableFallingEdge() {
    atomic {
      call Interrupt.disable();
      call HplInterrupt.edgeFalling();
      call HplInterrupt.enable();
    }
    return SUCCESS;
  }

  async command error_t Interrupt.disable() {
    atomic {
      call HplInterrupt.disable();
      call HplInterrupt.clear();        /* this is a really bad idea, can cause missing events, REVISIT x1, x2, x5 different */
    }
    return SUCCESS;
  }

  async event void HplInterrupt.fired() {
    call HplInterrupt.clear();          /* this is a really bad idea, can cause missing events, REVISIT x1, x2, x5 different */
    signal Interrupt.fired();
  }

}
