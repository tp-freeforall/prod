/*
 * Copyright (c) 2013, Eric B. Decker
 * Copyright (c) 2009-2010 People Power Company
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
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
 * @author David Moss
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

module PlatformPinsP {
  provides interface Init;
}

implementation {
  int i;

  command error_t Init.init() {
    atomic {

      /*
       * Assume connected to a CC2520EM module.  Need to make sure to set
       * the various enables and control signals to reasonable values to
       * make sure we don't confuse the chip.
       *
       * After reset all the digitial I/O pins are set to input.  Contents
       * of PxOUT will be random or what ever is left over from prior to the
       * reset.
       */

      /*
       * four bits in P1 we care about, cc_resetn (1pO) and cc_vreg_en (0pO).
       * clear out the two LED bits (to turn the leds off).
       */
      P1OUT = 0x04;
      P1DIR = 0x87;

      /* 1 bit in P3, cc_cs_n (1pO) */
      P3OUT = 0x01;
      P3DIR = 0x01;

      /* 1 bit in P4, turn unused LED off, nothing there */
      P4OUT = 0x00;
      P4DIR = 0x20;

      /* all other unused pins are left as inputs */

#if 0 /* Disabled: these specific setting are defaults, but others might not be */
      PMAPPWD = PMAPPW;                         // Get write-access to port mapping regs
      P1MAP5 = PM_UCA0RXD;                      // Map UCA0RXD output to P1.5
      P1MAP6 = PM_UCA0TXD;                      // Map UCA0TXD output to P1.6
      PMAPPWD = 0;                              // Lock port mapping registers
#endif //

    }
    return SUCCESS;
  }
}
