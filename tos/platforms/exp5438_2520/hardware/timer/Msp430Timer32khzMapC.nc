/*
 * Copyright (c) 2013, Eric B. Decker
 * Copyright (c) 2010, People Power Co.
 * Copyright (c) 2000-2003 The Regents of the University of California.
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

/**
 * Msp430Timer32khzMapC presents as paramaterized interfaces all of the 32khz
 * hardware timers on the MSP430 that are available for compile time allocation
 * by "new Alarm32khz16C()", "new AlarmMilli32C()", and so on.
 *
 * Platforms based on the MSP430 are encouraged to copy in and override this
 * file, presenting only the hardware timers that are available for allocation
 * on that platform.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Eric B. Decker <cire831@gmail.com>
 *
 *
 * x5 Msp430Timer32khzMapC
 *
 * x5 processors have at least two timer blocks, T0An and T1An.
 * The defaults from tos/chips/msp430/x5xxx/timer are T0An -> 32 KiHZ and
 * T1An -> TMicro.
 *
 * The exp5438_2520 platform (TI MSP-EXP430F5438 eval board) with the
 * CC2520EM (radio eval module) uses TMicro on T0An for SFD capture
 * from the Radio (CC2520).   This leaves T1An for use by the 32KiHz
 * subsystem.
 *
 * This module hands out control registers for T32khz (T1An) control cells.
 */

configuration Msp430Timer32khzMapC {
  provides {
    interface Msp430Timer[ uint8_t id ];
    interface Msp430TimerControl[ uint8_t id ];
    interface Msp430Compare[ uint8_t id ];
  }
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

#if defined(__MSP430_HAS_T1A5__)
  Msp430Timer[3] = Msp430TimerC.Timer1_A;
  Msp430TimerControl[3] = Msp430TimerC.Control1_A3;
  Msp430Compare[3] = Msp430TimerC.Compare1_A3;

  Msp430Timer[4] = Msp430TimerC.Timer1_A;
  Msp430TimerControl[4] = Msp430TimerC.Control1_A4;
  Msp430Compare[4] = Msp430TimerC.Compare1_A4;
#endif  /* __MSP430_HAS_T1A5__ */
}
