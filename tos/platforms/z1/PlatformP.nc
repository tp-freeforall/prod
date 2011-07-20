/*
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 2011 Eric B. Decker
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

/*
 * @author: Xavier Orduna <xorduna@dexmatech.com>
 * @author: Jordi Soucheiron <jsoucheiron@dexmatech.com>
 * @author: Eric B. Decker <cire831@gmail.com>
 */

#include "hardware.h"
 
module PlatformP{
  provides interface Init;
  uses interface Init as Msp430ClockInit;
  uses interface Init as LedsInit;
}
implementation {

  /*
   * We assume that the clock system after reset has been
   * set to some reasonable value.  ie ~1MHz.  We assume that
   * all the selects are 0, ie.  DIVA/1, XTS 0, XT2OFF, SELM 0,
   * DIVM/1, SELS 0, DIVS/1.  MCLK <- DCO, SMCLK <- DCO,
   * LFXT1S 32768, XCAP ~6pf
   *
   * We wait about a second for the 32KHz to stablize.
   *
   * PWR_UP_SEC is the number of times we need to wait for
   * TimerA to cycle (16 bits) when clocked at the default
   * msp430f2618 dco (about 1 MHz).
   */

#define PWR_UP_SEC 16

  void wait_for_32K() __attribute__ ((noinline)) {
    uint16_t left;

    TACTL = TACLR;			// also zeros out control bits
    TBCTL = TBCLR;
    TACTL = TASSEL_2 | MC_2;		// SMCLK/1, continuous
    TBCTL = TBSSEL_1 | MC_2;		//  ACLK/1, continuous
    TBCCTL0 = 0;

    /*
     * wait for about a sec for the 32KHz to come up and
     * stabilize.  We are guessing that it is stable and
     * on frequency after about a second but this needs
     * to be verified.
     *
     * FIX ME.  Need to verify stability of 32KHz.  It definitely
     * has a good looking waveform but what about its frequency
     * stability.  Needs to be measured.
     */
    left = PWR_UP_SEC;
    while (1) {
      if (TACTL & TAIFG) {
	/*
	 * wrapped, clear IFG, and decrement major count
	 */
	TACTL &= ~TAIFG;
	if (--left == 0)
	  break;
      }
    }
  }

  command error_t Init.init() {
    WDTCTL = WDTPW + WDTHOLD;
    wait_for_32K();
    call Msp430ClockInit.init();
    call LedsInit.init();
    return SUCCESS;
  }

  default command error_t LedsInit.init() { return SUCCESS; }

}
