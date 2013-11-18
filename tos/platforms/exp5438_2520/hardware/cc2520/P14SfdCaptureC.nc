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
 * The default for cc_gpio4 is to be SFD.  The CC2520EM module has this
 * pin wired to P8.1 on the mcu which is TA0.CCI1B.  Originally this
 * is what we used and required various mods to the timing system to
 * support the B variant.
 *
 * However, later we switched SFD over to cc_gpio0 which we program to
 * be SFD.  cc_gpio0 is wired to P1.4 on the mcu and is TA0.CCI3A.
 *
 * This effects what Timer components are exposed via Msp430TimerMicroMap
 * The platform needs to provide a modified map file.
 *
 * See tos/platforms/exp5438_2520/hardware/cc2520/HplCC2520C for details of
 * nesc wiring.
 *
 * This version of GpioCapture does not clear the IFG but rather relies
 * on the h/w clearing done by reading the IV.   X5 processors.
 */

module P14SfdCaptureC {
  provides interface GpioCaptureV2 as CaptureV2;
  uses {
    interface Msp430TimerControl;
    interface Msp430CaptureV2;
    interface HplMsp430GeneralIO as GeneralIO;
  }
}

implementation {

  error_t enableCapture( uint8_t mode ) {
    atomic {
      call Msp430TimerControl.disableEvents();
      call GeneralIO.makeInput();                               /* for capture to work must be input */
      call GeneralIO.selectModuleFunc();                        /* and must be assigned to the Module */

      /*
       * setControlAsCapture clears out both CCIE (pending Interrupt
       * as well as COV (overflow).
       */
      call Msp430TimerControl.setControlAsCapture( mode, MSP430TIMER_CCI_A );
      call Msp430TimerControl.enableEvents();
    }
    return SUCCESS;
  }

  async command error_t CaptureV2.captureRisingEdge() {
    return enableCapture( MSP430TIMER_CM_RISING );
  }

  async command error_t CaptureV2.captureFallingEdge() {
    return enableCapture( MSP430TIMER_CM_FALLING );
  }

  async command error_t CaptureV2.captureBothEdges() {
    return enableCapture( MSP430TIMER_CM_BOTH );
  }

  async command void CaptureV2.disable() {
    atomic {
      call Msp430TimerControl.disableEvents();
      call GeneralIO.selectIOFunc();
    }
  }

  async event void Msp430CaptureV2.captured( uint16_t time, bool overflowed ) {
    signal CaptureV2.captured( time, overflowed );
  }
}
