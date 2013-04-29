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
 * The x5 processors have at least two timer blocks, T0An and T1An.
 * T0An is assigned to 32KHiZ timing (TMilli) and T1An is assigned
 * to TMicro.  This module hands out control registers for the T1An
 * control cells.
 */

configuration Msp430TimerMicroMapC {
  provides interface Msp430Timer[ uint8_t id ];
  provides interface Msp430TimerControl[ uint8_t id ];
  provides interface Msp430Compare[ uint8_t id ];
}
implementation {
  components Msp430TimerC;

  Msp430Timer[0] = Msp430TimerC.Timer1_A;
  Msp430TimerControl[0] = Msp430TimerC.Control1_A0;
  Msp430Compare[0] = Msp430TimerC.Compare1_A0;

  Msp430Timer[1] = Msp430TimerC.Timer1_A;
  Msp430TimerControl[1] = Msp430TimerC.Control1_A1;
  Msp430Compare[1] = Msp430TimerC.Compare1_A1;

  Msp430Timer[2] = Msp430TimerC.Timer1_A;
  Msp430TimerControl[2] = Msp430TimerC.Control1_A2;
  Msp430Compare[2] = Msp430TimerC.Compare1_A2;
}
