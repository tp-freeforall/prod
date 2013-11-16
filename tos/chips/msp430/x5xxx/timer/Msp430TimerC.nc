/*
 * Copyright (c) 2011, 2013 Eric B. Decker
 * Copyright (c) 2009-2010 People Power Co.
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
 * TinyOS Msp430 support started with the msp430f1611 which provided
 * 1 TA3 (3 CCRs) and 1 TB7 (7 CCRs).   The cc430 and 5438 cpus (both x5)
 * provide a T0A5 and T1A3 but no TBs.  Other chips in the MSP430XV2
 * series have different suites.  Current TI headers indicate the
 * following sets are available:
 *
 * T0A3, T0A5
 * T1A2 T1A3 T1A5
 * T2A3
 * T0B7
 * T0D3, T1D3
 *
 * TA3 is also defined but not in any of the x5 cpu headers.   This may
 * become an issue when we start to support the x4 family.
 *
 * Timer_B extends Timer_A with some extra features that are not
 * currently supported in TinyOS.  Until those features are needed,
 * Timer_B instances use the same interfaces as Timer_A instances.
 * Ditto for Timer_D.
 *
 * This module implements the Msp430CaptureV2 interface which
 * includes support for Capture Overflow indications.
 *
 * @note As of this writing, only T0A5 and T1A3 have been tested.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

configuration Msp430TimerC {
#if defined(__MSP430_HAS_T0A3__) || defined(__MSP430_HAS_T0A5__)
  provides interface Msp430Timer as Timer0_A;

  provides interface Msp430TimerControl as Control0_A0;
  provides interface Msp430Compare as Compare0_A0;
  provides interface Msp430CaptureV2 as Capture0_A0;

  provides interface Msp430TimerControl as Control0_A1;
  provides interface Msp430Compare as Compare0_A1;
  provides interface Msp430CaptureV2 as Capture0_A1;

  provides interface Msp430TimerControl as Control0_A2;
  provides interface Msp430Compare as Compare0_A2;
  provides interface Msp430CaptureV2 as Capture0_A2;

#if defined(__MSP430_HAS_T0A5__)
  provides interface Msp430TimerControl as Control0_A3;
  provides interface Msp430Compare as Compare0_A3;
  provides interface Msp430CaptureV2 as Capture0_A3;

  provides interface Msp430TimerControl as Control0_A4;
  provides interface Msp430Compare as Compare0_A4;
  provides interface Msp430CaptureV2 as Capture0_A4;
#endif /* __MSP430_HAS_T0A5__ */
#endif /* __MSP430_HAS_T0A3__ || __MSP430_HAS_T0A5__ */

#if defined(__MSP430_HAS_T0B7__)
  provides interface Msp430Timer as Timer0_B;

  provides interface Msp430TimerControl as Control0_B0;
  provides interface Msp430Compare as Compare0_B0;
  provides interface Msp430CaptureV2 as Capture0_B0;

  provides interface Msp430TimerControl as Control0_B1;
  provides interface Msp430Compare as Compare0_B1;
  provides interface Msp430CaptureV2 as Capture0_B1;

  provides interface Msp430TimerControl as Control0_B2;
  provides interface Msp430Compare as Compare0_B2;
  provides interface Msp430CaptureV2 as Capture0_B2;

  provides interface Msp430TimerControl as Control0_B3;
  provides interface Msp430Compare as Compare0_B3;
  provides interface Msp430CaptureV2 as Capture0_B3;

  provides interface Msp430TimerControl as Control0_B4;
  provides interface Msp430Compare as Compare0_B4;
  provides interface Msp430CaptureV2 as Capture0_B4;

  provides interface Msp430TimerControl as Control0_B5;
  provides interface Msp430Compare as Compare0_B5;
  provides interface Msp430CaptureV2 as Capture0_B5;

  provides interface Msp430TimerControl as Control0_B6;
  provides interface Msp430Compare as Compare0_B6;
  provides interface Msp430CaptureV2 as Capture0_B6;
#endif /* __MSP430_HAS_T0B7__ */

#if defined(__MSP430_HAS_T1A2__) || defined(__MSP430_HAS_T1A3__) || defined(__MSP430_HAS_T1A5__)
  provides interface Msp430Timer as Timer1_A;

  provides interface Msp430TimerControl as Control1_A0;
  provides interface Msp430Compare as Compare1_A0;
  provides interface Msp430CaptureV2 as Capture1_A0;

  provides interface Msp430TimerControl as Control1_A1;
  provides interface Msp430Compare as Compare1_A1;
  provides interface Msp430CaptureV2 as Capture1_A1;

#if defined(__MSP430_HAS_T1A3__) || defined(__MSP430_HAS_T1A5__)
  provides interface Msp430TimerControl as Control1_A2;
  provides interface Msp430Compare as Compare1_A2;
  provides interface Msp430CaptureV2 as Capture1_A2;

#if defined(__MSP430_HAS_T1A5__)
  provides interface Msp430TimerControl as Control1_A3;
  provides interface Msp430Compare as Compare1_A3;
  provides interface Msp430CaptureV2 as Capture1_A3;

  provides interface Msp430TimerControl as Control1_A4;
  provides interface Msp430Compare as Compare1_A4;
  provides interface Msp430CaptureV2 as Capture1_A4;
#endif /* __MSP430_HAS_T1A5__ */
#endif /* __MSP430_HAS_T1A3__ || __MSP430_HAS_T1A5__ */
#endif /* __MSP430_HAS_T1A2__ || __MSP430_HAS_T1A3__ || __MSP430_HAS_T1A5__ */


#if defined(__MSP430_HAS_T2A3__)
  provides interface Msp430Timer as Timer2_A;

  provides interface Msp430TimerControl as Control2_A0;
  provides interface Msp430Compare as Compare2_A0;
  provides interface Msp430CaptureV2 as Capture2_A0;

  provides interface Msp430TimerControl as Control2_A1;
  provides interface Msp430Compare as Compare2_A1;
  provides interface Msp430CaptureV2 as Capture2_A1;

  provides interface Msp430TimerControl as Control2_A2;
  provides interface Msp430Compare as Compare2_A2;
  provides interface Msp430CaptureV2 as Capture2_A2;
#endif /* __MSP430_HAS_T2A3__ */

}
implementation {
  components Msp430TimerCommonP as Common;

#if defined(__MSP430_HAS_T0A3__) || defined(__MSP430_HAS_T0A5__)
  components new Msp430TimerP( TA0IV_, TA0R_, TA0CTL_, TAIFG, TACLR, TAIE,
			       TASSEL0, TASSEL1, FALSE ) as Msp430Timer0_A;

  Timer0_A = Msp430Timer0_A.Timer;
  Msp430Timer0_A.VectorTimerX0 -> Common.VectorTimer0_A0;
  Msp430Timer0_A.VectorTimerX1 -> Common.VectorTimer0_A1;
  Msp430Timer0_A.Overflow -> Msp430Timer0_A.Event[7];

  components new Msp430TimerCapComP( TA0CCTL0_, TA0CCR0_ ) as Msp430Timer0_A0;
  Control0_A0 = Msp430Timer0_A0.Control;
  Compare0_A0 = Msp430Timer0_A0.Compare;
  Capture0_A0 = Msp430Timer0_A0.Capture;
  Msp430Timer0_A0.Timer -> Msp430Timer0_A.Timer;
  Msp430Timer0_A0.Event -> Msp430Timer0_A.Event[0];

  components new Msp430TimerCapComP( TA0CCTL1_, TA0CCR1_ ) as Msp430Timer0_A1;
  Control0_A1 = Msp430Timer0_A1.Control;
  Compare0_A1 = Msp430Timer0_A1.Compare;
  Capture0_A1 = Msp430Timer0_A1.Capture;
  Msp430Timer0_A1.Timer -> Msp430Timer0_A.Timer;
  Msp430Timer0_A1.Event -> Msp430Timer0_A.Event[1];

  components new Msp430TimerCapComP( TA0CCTL2_, TA0CCR2_ ) as Msp430Timer0_A2;
  Control0_A2 = Msp430Timer0_A2.Control;
  Compare0_A2 = Msp430Timer0_A2.Compare;
  Capture0_A2 = Msp430Timer0_A2.Capture;
  Msp430Timer0_A2.Timer -> Msp430Timer0_A.Timer;
  Msp430Timer0_A2.Event -> Msp430Timer0_A.Event[2];

#if defined(__MSP430_HAS_T0A5__)
  components new Msp430TimerCapComP( TA0CCTL3_, TA0CCR3_ ) as Msp430Timer0_A3;
  Control0_A3 = Msp430Timer0_A3.Control;
  Compare0_A3 = Msp430Timer0_A3.Compare;
  Capture0_A3 = Msp430Timer0_A3.Capture;
  Msp430Timer0_A3.Timer -> Msp430Timer0_A.Timer;
  Msp430Timer0_A3.Event -> Msp430Timer0_A.Event[3];

  components new Msp430TimerCapComP( TA0CCTL4_, TA0CCR4_ ) as Msp430Timer0_A4;
  Control0_A4 = Msp430Timer0_A4.Control;
  Compare0_A4 = Msp430Timer0_A4.Compare;
  Capture0_A4 = Msp430Timer0_A4.Capture;
  Msp430Timer0_A4.Timer -> Msp430Timer0_A.Timer;
  Msp430Timer0_A4.Event -> Msp430Timer0_A.Event[4];

#endif /* __MSP430_HAS_T0A5__ */
#endif /* __MSP430_HAS_T0A3__ || __MSP430_HAS_T0A5__ */


#if defined(__MSP430_HAS_T0B7__)
  components new Msp430TimerP( TB0IV_, TB0R_, TB0CTL_, TBIFG, TBCLR, TBIE,
			       TBSSEL0, TBSSEL1, FALSE ) as Msp430Timer0_B;

  Timer0_B = Msp430Timer0_B.Timer;
  Msp430Timer0_B.VectorTimerX0 -> Common.VectorTimer0_B0;
  Msp430Timer0_B.VectorTimerX1 -> Common.VectorTimer0_B1;
  Msp430Timer0_B.Overflow -> Msp430Timer0_B.Event[7];

  components new Msp430TimerCapComP( TB0CCTL0_, TB0CCR0_ ) as Msp430Timer0_B0;
  Control0_B0 = Msp430Timer0_B0.Control;
  Compare0_B0 = Msp430Timer0_B0.Compare;
  Capture0_B0 = Msp430Timer0_B0.Capture;
  Msp430Timer0_B0.Timer -> Msp430Timer0_B.Timer;
  Msp430Timer0_B0.Event -> Msp430Timer0_B.Event[0];

  components new Msp430TimerCapComP( TB0CCTL1_, TB0CCR1_ ) as Msp430Timer0_B1;
  Control0_B1 = Msp430Timer0_B1.Control;
  Compare0_B1 = Msp430Timer0_B1.Compare;
  Capture0_B1 = Msp430Timer0_B1.Capture;
  Msp430Timer0_B1.Timer -> Msp430Timer0_B.Timer;
  Msp430Timer0_B1.Event -> Msp430Timer0_B.Event[1];

  components new Msp430TimerCapComP( TB0CCTL2_, TB0CCR2_ ) as Msp430Timer0_B2;
  Control0_B2 = Msp430Timer0_B2.Control;
  Compare0_B2 = Msp430Timer0_B2.Compare;
  Capture0_B2 = Msp430Timer0_B2.Capture;
  Msp430Timer0_B2.Timer -> Msp430Timer0_B.Timer;
  Msp430Timer0_B2.Event -> Msp430Timer0_B.Event[2];

  components new Msp430TimerCapComP( TB0CCTL3_, TB0CCR3_ ) as Msp430Timer0_B3;
  Control0_B3 = Msp430Timer0_B3.Control;
  Compare0_B3 = Msp430Timer0_B3.Compare;
  Capture0_B3 = Msp430Timer0_B3.Capture;
  Msp430Timer0_B3.Timer -> Msp430Timer0_B.Timer;
  Msp430Timer0_B3.Event -> Msp430Timer0_B.Event[3];

  components new Msp430TimerCapComP( TB0CCTL4_, TB0CCR4_ ) as Msp430Timer0_B4;
  Control0_B4 = Msp430Timer0_B4.Control;
  Compare0_B4 = Msp430Timer0_B4.Compare;
  Capture0_B4 = Msp430Timer0_B4.Capture;
  Msp430Timer0_B4.Timer -> Msp430Timer0_B.Timer;
  Msp430Timer0_B4.Event -> Msp430Timer0_B.Event[4];

  components new Msp430TimerCapComP( TB0CCTL5_, TB0CCR5_ ) as Msp430Timer0_B5;
  Control0_B5 = Msp430Timer0_B5.Control;
  Compare0_B5 = Msp430Timer0_B5.Compare;
  Capture0_B5 = Msp430Timer0_B5.Capture;
  Msp430Timer0_B5.Timer -> Msp430Timer0_B.Timer;
  Msp430Timer0_B5.Event -> Msp430Timer0_B.Event[5];

  components new Msp430TimerCapComP( TB0CCTL6_, TB0CCR6_ ) as Msp430Timer0_B6;
  Control0_B6 = Msp430Timer0_B6.Control;
  Compare0_B6 = Msp430Timer0_B6.Compare;
  Capture0_B6 = Msp430Timer0_B6.Capture;
  Msp430Timer0_B6.Timer -> Msp430Timer0_B.Timer;
  Msp430Timer0_B6.Event -> Msp430Timer0_B.Event[6];

#endif /* __MSP430_HAS_T0B7__ */


#if defined(__MSP430_HAS_T1A2__) || defined(__MSP430_HAS_T1A3__) || defined(__MSP430_HAS_T1A5__)
  components new Msp430TimerP( TA1IV_, TA1R_, TA1CTL_, TAIFG, TACLR, TAIE,
			       TASSEL0, TASSEL1, FALSE ) as Msp430Timer1_A;

  Timer1_A = Msp430Timer1_A.Timer;
  Msp430Timer1_A.VectorTimerX0 -> Common.VectorTimer1_A0;
  Msp430Timer1_A.VectorTimerX1 -> Common.VectorTimer1_A1;
  Msp430Timer1_A.Overflow -> Msp430Timer1_A.Event[7];

  components new Msp430TimerCapComP( TA1CCTL0_, TA1CCR0_ ) as Msp430Timer1_A0;
  Control1_A0 = Msp430Timer1_A0.Control;
  Compare1_A0 = Msp430Timer1_A0.Compare;
  Capture1_A0 = Msp430Timer1_A0.Capture;
  Msp430Timer1_A0.Timer -> Msp430Timer1_A.Timer;
  Msp430Timer1_A0.Event -> Msp430Timer1_A.Event[0];

  components new Msp430TimerCapComP( TA1CCTL1_, TA1CCR1_ ) as Msp430Timer1_A1;
  Control1_A1 = Msp430Timer1_A1.Control;
  Compare1_A1 = Msp430Timer1_A1.Compare;
  Capture1_A1 = Msp430Timer1_A1.Capture;
  Msp430Timer1_A1.Timer -> Msp430Timer1_A.Timer;
  Msp430Timer1_A1.Event -> Msp430Timer1_A.Event[1];

#if defined(__MSP430_HAS_T1A3__) || defined(__MSP430_HAS_T1A5__)
  components new Msp430TimerCapComP( TA1CCTL2_, TA1CCR2_ ) as Msp430Timer1_A2;
  Control1_A2 = Msp430Timer1_A2.Control;
  Compare1_A2 = Msp430Timer1_A2.Compare;
  Capture1_A2 = Msp430Timer1_A2.Capture;
  Msp430Timer1_A2.Timer -> Msp430Timer1_A.Timer;
  Msp430Timer1_A2.Event -> Msp430Timer1_A.Event[2];

#if defined(__MSP430_HAS_T1A5__)
  components new Msp430TimerCapComP( TA1CCTL3_, TA1CCR3_ ) as Msp430Timer1_A3;
  Control1_A3 = Msp430Timer1_A3.Control;
  Compare1_A3 = Msp430Timer1_A3.Compare;
  Capture1_A3 = Msp430Timer1_A3.Capture;
  Msp430Timer1_A3.Timer -> Msp430Timer1_A.Timer;
  Msp430Timer1_A3.Event -> Msp430Timer1_A.Event[3];

  components new Msp430TimerCapComP( TA1CCTL4_, TA1CCR4_ ) as Msp430Timer1_A4;
  Control1_A4 = Msp430Timer1_A4.Control;
  Compare1_A4 = Msp430Timer1_A4.Compare;
  Capture1_A4 = Msp430Timer1_A4.Capture;
  Msp430Timer1_A4.Timer -> Msp430Timer1_A.Timer;
  Msp430Timer1_A4.Event -> Msp430Timer1_A.Event[4];

#endif /* __MSP430_HAS_T1A5__ */
#endif /* __MSP430_HAS_T1A3__ || __MSP430_HAS_T1A5__ */
#endif /* __MSP430_HAS_T1A2__ || __MSP430_HAS_T1A3__ || __MSP430_HAS_T1A5__ */


#if defined(__MSP430_HAS_T2A3__)
  components new Msp430TimerP( TA2IV_, TA2R_, TA2CTL_, TAIFG, TACLR, TAIE,
			       TASSEL0, TASSEL1, FALSE ) as Msp430Timer2_A;

  Timer2_A = Msp430Timer2_A.Timer;
  Msp430Timer2_A.VectorTimerX0 -> Common.VectorTimer2_A0;
  Msp430Timer2_A.VectorTimerX1 -> Common.VectorTimer2_A1;
  Msp430Timer2_A.Overflow -> Msp430Timer2_A.Event[7];

  components new Msp430TimerCapComP( TA2CCTL0_, TA2CCR0_ ) as Msp430Timer2_A0;
  Control2_A0 = Msp430Timer2_A0.Control;
  Compare2_A0 = Msp430Timer2_A0.Compare;
  Capture2_A0 = Msp430Timer2_A0.Capture;
  Msp430Timer2_A0.Timer -> Msp430Timer2_A.Timer;
  Msp430Timer2_A0.Event -> Msp430Timer2_A.Event[0];

  components new Msp430TimerCapComP( TA2CCTL1_, TA2CCR1_ ) as Msp430Timer2_A1;
  Control2_A1 = Msp430Timer2_A1.Control;
  Compare2_A1 = Msp430Timer2_A1.Compare;
  Capture2_A1 = Msp430Timer2_A1.Capture;
  Msp430Timer2_A1.Timer -> Msp430Timer2_A.Timer;
  Msp430Timer2_A1.Event -> Msp430Timer2_A.Event[1];

  components new Msp430TimerCapComP( TA2CCTL2_, TA2CCR2_ ) as Msp430Timer2_A2;
  Control2_A2 = Msp430Timer2_A2.Control;
  Compare2_A2 = Msp430Timer2_A2.Compare;
  Capture2_A2 = Msp430Timer2_A2.Capture;
  Msp430Timer2_A2.Timer -> Msp430Timer2_A.Timer;
  Msp430Timer2_A2.Event -> Msp430Timer2_A.Event[2];

#endif /* __MSP430_HAS_T2A3__ */
}
