/*
 * Copyright (c) 2010 People Power Co.
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

configuration PlatformAdcC {
  provides {
      interface HplMsp430GeneralIO as A0;
      interface HplMsp430GeneralIO as A1;
      interface HplMsp430GeneralIO as A2;
      interface HplMsp430GeneralIO as A3;
      interface HplMsp430GeneralIO as A4;
      interface HplMsp430GeneralIO as A5;

      interface Msp430Timer as TimerA;
      interface Msp430TimerControl as ControlA0;
      interface Msp430TimerControl as ControlA1;
      interface Msp430Compare as CompareA0;
      interface Msp430Compare as CompareA1;
  }	
}

implementation {

  components HplMsp430GeneralIOC;
  A0 = HplMsp430GeneralIOC.Port20;
  A1 = HplMsp430GeneralIOC.Port21;
  A2 = HplMsp430GeneralIOC.Port22;
  A3 = HplMsp430GeneralIOC.Port23;
  A4 = HplMsp430GeneralIOC.Port24;
  A5 = HplMsp430GeneralIOC.Port25;

  components Msp430TimerC;
  TimerA = Msp430TimerC.Timer0_A;
  ControlA0 = Msp430TimerC.Control0_A0;
  ControlA1 = Msp430TimerC.Control0_A1;
  CompareA0 = Msp430TimerC.Compare0_A0;
  CompareA1 = Msp430TimerC.Compare0_A1;
}
