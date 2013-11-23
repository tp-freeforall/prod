/*
 * Copyright (c) 2013, Eric B. Decker
 * Copyright (c) 2010, Vanderbilt University
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
 *
 * Author: Eric B. Decker <cire831@gmail.com>
 *
 * x5 Msp430TimerMicroMapC
 *
 * x5 processors have at least two timer blocks, T0An and T1An.
 * The defaults from tos/chips/msp430/x5xxx/timer are T0An -> 32 KiHZ and
 * T1An -> TMicro.
 *
 * The exp5438 platforms use the TI MSP-EXP430F5438 eval board possibly
 * coupled with a radio eval module (CC2520EM or CC2520-2591EM).  The
 * exp5438_2520 platform uses the CC2520EM and wants TMicro on T0An because
 * the SFD pin is wired to T0A1 for timestamping (gpio4 from the CC2520 chip,
 * wired to P14/TA0.3/CCI3A on the MCU).
 *
 * We also use a TMicro MSP430 Timer for running the CC2520 state machine.
 * T0An has more control modules (5, T0A0-T0A4) so this works better.
 *
 * This module hands out control registers for TMicro (T0An) control cells.
 *
 * Control0_A3 and Compare0_A3 are dedicated to SFDCapture and aren't
 * available for assignment.
 *
 * For the exp5438_2520 mote we need to flip which timer block is assigned
 * to Tmicro and Tmilli/32KiHz).  Default is TA0 -> 32KiHz (TMilli)
 * and TA1 -> 1MHz.   We flip this.  We need TMicro on TA0 for TMicro
 * timestamps because of SFD captures.
 */

configuration Msp430TimerMicroMapC {
  provides interface Msp430Timer[ uint8_t id ];
  provides interface Msp430TimerControl[ uint8_t id ];
  provides interface Msp430Compare[ uint8_t id ];
}
implementation {
  components Msp430TimerC;

  Msp430Timer[0] = Msp430TimerC.Timer0_A;
  Msp430TimerControl[0] = Msp430TimerC.Control0_A0;
  Msp430Compare[0] = Msp430TimerC.Compare0_A0;

  Msp430Timer[1] = Msp430TimerC.Timer0_A;
  Msp430TimerControl[1] = Msp430TimerC.Control0_A1;
  Msp430Compare[1] = Msp430TimerC.Compare0_A1;

  Msp430Timer[2] = Msp430TimerC.Timer0_A;
  Msp430TimerControl[2] = Msp430TimerC.Control0_A2;
  Msp430Compare[2] = Msp430TimerC.Compare0_A2;

#if defined(__MSP430_HAS_T0A5__)
#ifdef notdef
  /* allocated in HplCC2520C.nc to SFDCapture */
  Msp430Timer[3] = Msp430TimerC.Timer0_A;
  Msp430TimerControl[3] = Msp430TimerC.Control0_A3;
  Msp430Compare[3] = Msp430TimerC.Compare0_A3;
#endif

  Msp430Timer[3] = Msp430TimerC.Timer0_A;
  Msp430TimerControl[3] = Msp430TimerC.Control0_A4;
  Msp430Compare[3] = Msp430TimerC.Compare0_A4;
#endif  /* __MSP430_HAS_T0A5__ */
}
