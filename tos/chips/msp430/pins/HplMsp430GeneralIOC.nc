/**
 * Copyright (c) 2012 Eric B. Decker
 * Copyright (c) 2011 João Gonçalves
 * Copyright (c) 2011 Eric B. Decker
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 2000-2003 The Regents of the University of California.  
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
 * Digital pin i/o abstraction, TI MSP430 processors.
 *
 * @author Joe Polastre
 * @author Xavier Orduna <xorduna@dexmatech.com>
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Eric B. Decker <cire831@gmail.com>
 * @author João Gonçalves <joao.m.goncalves@ist.utl.pt>
 */

configuration HplMsp430GeneralIOC {
  // provides all the ports as raw ports
#if defined(__msp430_have_port1) || defined(__MSP430_HAS_PORT1__) || defined(__MSP430_HAS_PORT1_R__)
  provides interface HplMsp430GeneralIO as Port10;
  provides interface HplMsp430GeneralIO as Port11;
  provides interface HplMsp430GeneralIO as Port12;
  provides interface HplMsp430GeneralIO as Port13;
  provides interface HplMsp430GeneralIO as Port14;
  provides interface HplMsp430GeneralIO as Port15;
  provides interface HplMsp430GeneralIO as Port16;
  provides interface HplMsp430GeneralIO as Port17;
#endif

#if defined(__msp430_have_port2) || defined(__MSP430_HAS_PORT2__) || defined(__MSP430_HAS_PORT2_R__)
  provides interface HplMsp430GeneralIO as Port20;
  provides interface HplMsp430GeneralIO as Port21;
  provides interface HplMsp430GeneralIO as Port22;
  provides interface HplMsp430GeneralIO as Port23;
  provides interface HplMsp430GeneralIO as Port24;
  provides interface HplMsp430GeneralIO as Port25;
  provides interface HplMsp430GeneralIO as Port26;
  provides interface HplMsp430GeneralIO as Port27;
#endif

#if defined(__msp430_have_port3) || defined(__MSP430_HAS_PORT3__) || defined(__MSP430_HAS_PORT3_R__)
  provides interface HplMsp430GeneralIO as Port30;
  provides interface HplMsp430GeneralIO as Port31;
  provides interface HplMsp430GeneralIO as Port32;
  provides interface HplMsp430GeneralIO as Port33;
  provides interface HplMsp430GeneralIO as Port34;
  provides interface HplMsp430GeneralIO as Port35;
  provides interface HplMsp430GeneralIO as Port36;
  provides interface HplMsp430GeneralIO as Port37;
#endif

#if defined(__msp430_have_port4) || defined(__MSP430_HAS_PORT4__) || defined(__MSP430_HAS_PORT4_R__)
  provides interface HplMsp430GeneralIO as Port40;
  provides interface HplMsp430GeneralIO as Port41;
  provides interface HplMsp430GeneralIO as Port42;
  provides interface HplMsp430GeneralIO as Port43;
  provides interface HplMsp430GeneralIO as Port44;
  provides interface HplMsp430GeneralIO as Port45;
  provides interface HplMsp430GeneralIO as Port46;
  provides interface HplMsp430GeneralIO as Port47;
#endif

#if defined(__msp430_have_port5) || defined(__MSP430_HAS_PORT5__) || defined(__MSP430_HAS_PORT5_R__)
  provides interface HplMsp430GeneralIO as Port50;
  provides interface HplMsp430GeneralIO as Port51;
  provides interface HplMsp430GeneralIO as Port52;
  provides interface HplMsp430GeneralIO as Port53;
  provides interface HplMsp430GeneralIO as Port54;
  provides interface HplMsp430GeneralIO as Port55;
  provides interface HplMsp430GeneralIO as Port56;
  provides interface HplMsp430GeneralIO as Port57;
#endif

#if defined(__msp430_have_port6) || defined(__MSP430_HAS_PORT6__) || defined(__MSP430_HAS_PORT6_R__)
  provides interface HplMsp430GeneralIO as Port60;
  provides interface HplMsp430GeneralIO as Port61;
  provides interface HplMsp430GeneralIO as Port62;
  provides interface HplMsp430GeneralIO as Port63;
  provides interface HplMsp430GeneralIO as Port64;
  provides interface HplMsp430GeneralIO as Port65;
  provides interface HplMsp430GeneralIO as Port66;
  provides interface HplMsp430GeneralIO as Port67;
#endif

#if defined(__msp430_have_port7) || defined(__MSP430_HAS_PORT7__) || defined(__MSP430_HAS_PORT7_R__)
  provides interface HplMsp430GeneralIO as Port70;
  provides interface HplMsp430GeneralIO as Port71;
  provides interface HplMsp430GeneralIO as Port72;
  provides interface HplMsp430GeneralIO as Port73;
  provides interface HplMsp430GeneralIO as Port74;
  provides interface HplMsp430GeneralIO as Port75;
  provides interface HplMsp430GeneralIO as Port76;
  provides interface HplMsp430GeneralIO as Port77;
#endif

#if defined(__msp430_have_port8) || defined(__MSP430_HAS_PORT8__) || defined(__MSP430_HAS_PORT8_R__)
  provides interface HplMsp430GeneralIO as Port80;
  provides interface HplMsp430GeneralIO as Port81;
  provides interface HplMsp430GeneralIO as Port82;
  provides interface HplMsp430GeneralIO as Port83;
  provides interface HplMsp430GeneralIO as Port84;
  provides interface HplMsp430GeneralIO as Port85;
  provides interface HplMsp430GeneralIO as Port86;
  provides interface HplMsp430GeneralIO as Port87;
#endif

#if defined(__msp430_have_port9) || defined(__MSP430_HAS_PORT9__) || defined(__MSP430_HAS_PORT9_R__)
  provides interface HplMsp430GeneralIO as Port90;
  provides interface HplMsp430GeneralIO as Port91;
  provides interface HplMsp430GeneralIO as Port92;
  provides interface HplMsp430GeneralIO as Port93;
  provides interface HplMsp430GeneralIO as Port94;
  provides interface HplMsp430GeneralIO as Port95;
  provides interface HplMsp430GeneralIO as Port96;
  provides interface HplMsp430GeneralIO as Port97;
#endif

#if defined(__msp430_have_port10) || defined(__MSP430_HAS_PORT10__) || defined(__MSP430_HAS_PORT10_R__)
  provides interface HplMsp430GeneralIO as Port100;
  provides interface HplMsp430GeneralIO as Port101;
  provides interface HplMsp430GeneralIO as Port102;
  provides interface HplMsp430GeneralIO as Port103;
  provides interface HplMsp430GeneralIO as Port104;
  provides interface HplMsp430GeneralIO as Port105;
  provides interface HplMsp430GeneralIO as Port106;
  provides interface HplMsp430GeneralIO as Port107;
#endif
#if defined(__msp430_have_port11) || defined(__MSP430_HAS_PORT11__) || defined(__MSP430_HAS_PORT11_R__)
  provides interface HplMsp430GeneralIO as Port110;
  provides interface HplMsp430GeneralIO as Port111;
  provides interface HplMsp430GeneralIO as Port112;
  provides interface HplMsp430GeneralIO as Port113;
  provides interface HplMsp430GeneralIO as Port114;
  provides interface HplMsp430GeneralIO as Port115;
  provides interface HplMsp430GeneralIO as Port116;
  provides interface HplMsp430GeneralIO as Port117;
#endif

#if defined (__msp430_have_portj) || defined(__MSP430_HAS_PORTJ__) || defined(__MSP430_HAS_PORTJ_R__)
  provides interface HplMsp430GeneralIO as PortJ0;
  provides interface HplMsp430GeneralIO as PortJ1;
  provides interface HplMsp430GeneralIO as PortJ2;
  provides interface HplMsp430GeneralIO as PortJ3;
#endif

  // provides special ports explicitly
  // this section of HplMsp430GeneralIOC supports the F14x and F16x series
  // x1 family: msp430f149 and msp430f1611

#if defined(__msp430x14x) || defined(__msp430x16x)
  provides interface HplMsp430GeneralIO as STE0;
  provides interface HplMsp430GeneralIO as SIMO0;
  provides interface HplMsp430GeneralIO as SOMI0;
  provides interface HplMsp430GeneralIO as UCLK0;
  provides interface HplMsp430GeneralIO as UTXD0;
  provides interface HplMsp430GeneralIO as URXD0;

  provides interface HplMsp430GeneralIO as STE1;
  provides interface HplMsp430GeneralIO as SIMO1;
  provides interface HplMsp430GeneralIO as SOMI1;
  provides interface HplMsp430GeneralIO as UCLK1;
  provides interface HplMsp430GeneralIO as UTXD1;
  provides interface HplMsp430GeneralIO as URXD1;

  provides interface HplMsp430GeneralIO as ADC0;
  provides interface HplMsp430GeneralIO as ADC1;
  provides interface HplMsp430GeneralIO as ADC2;
  provides interface HplMsp430GeneralIO as ADC3;
  provides interface HplMsp430GeneralIO as ADC4;
  provides interface HplMsp430GeneralIO as ADC5;
  provides interface HplMsp430GeneralIO as ADC6;
  provides interface HplMsp430GeneralIO as ADC7;

#ifdef __msp430x16x
  provides interface HplMsp430GeneralIO as SDA;
  provides interface HplMsp430GeneralIO as SCL;

  provides interface HplMsp430GeneralIO as DAC0;
  provides interface HplMsp430GeneralIO as DAC1;

  provides interface HplMsp430GeneralIO as SVSIN;
  provides interface HplMsp430GeneralIO as SVSOUT;
#endif /* __msp430x16x */
#endif /* __msp430x14x || __msp430x16x */


/*
 * x2 family: msp430f2{4,6}1[6-9] processors
 *
 *	__msp430x24x:	msp430f24[7-9], msp430f2410
 *	__msp430x241x:	msp430f241[6-9]
 *	__msp430x26x:	msp430f261[6-9]
 *	__msp430x261x:	new headers none, 3.2.3 headers: msp430x261x.h
 *
 * Note: 247, 248, 249, and 2410 aren't currently used for a tinyos platform.
 * 241[6-9] and 261[6-9] are used by tinyos platforms.
 *
 * Old headers: mspgccX (3.2.3) includes msp430x261x.h (-mmcu=msp430f2617)
 * which defines __msp430x261x.
 *
 * New headers: mspgcc4 (4.4.5, uniarch, TI_HEADERS) defines __msp430x26x.  There
 * doesn't look like there is any conflict with any other processor defines.
 *
 * Differences between 2410 and 241x:
 *	241x processors MSP430X_CPU
 *	241x include ports 7 and 8.
 */
#if defined(__msp430x241x) || defined(__msp430x261x) || defined(__msp430x26x)
  provides interface HplMsp430GeneralIO as UCA0CLK;
  provides interface HplMsp430GeneralIO as UCA0STE;
  provides interface HplMsp430GeneralIO as UCA0TXD;
  provides interface HplMsp430GeneralIO as UCA0RXD;
  provides interface HplMsp430GeneralIO as UCA0SIMO;
  provides interface HplMsp430GeneralIO as UCA0SOMI;

  provides interface HplMsp430GeneralIO as UCB0CLK;  
  provides interface HplMsp430GeneralIO as UCB0STE;
  provides interface HplMsp430GeneralIO as UCB0SIMO;
  provides interface HplMsp430GeneralIO as UCB0SOMI;
  provides interface HplMsp430GeneralIO as UCB0SDA;
  provides interface HplMsp430GeneralIO as UCB0SCL;

  provides interface HplMsp430GeneralIO as UCA1CLK;
  provides interface HplMsp430GeneralIO as UCA1STE;
  provides interface HplMsp430GeneralIO as UCA1TXD;
  provides interface HplMsp430GeneralIO as UCA1RXD;
  provides interface HplMsp430GeneralIO as UCA1SIMO;
  provides interface HplMsp430GeneralIO as UCA1SOMI;

  provides interface HplMsp430GeneralIO as UCB1CLK;
  provides interface HplMsp430GeneralIO as UCB1STE;
  provides interface HplMsp430GeneralIO as UCB1SIMO;
  provides interface HplMsp430GeneralIO as UCB1SOMI;
  provides interface HplMsp430GeneralIO as UCB1SDA;
  provides interface HplMsp430GeneralIO as UCB1SCL;

  provides interface HplMsp430GeneralIO as ADC0;
  provides interface HplMsp430GeneralIO as ADC1;
  provides interface HplMsp430GeneralIO as ADC2;
  provides interface HplMsp430GeneralIO as ADC3;
  provides interface HplMsp430GeneralIO as ADC4;
  provides interface HplMsp430GeneralIO as ADC5;
  provides interface HplMsp430GeneralIO as ADC6;
  provides interface HplMsp430GeneralIO as ADC7;

  provides interface HplMsp430GeneralIO as SVSIN;
  provides interface HplMsp430GeneralIO as SVSOUT;

#if defined(__msp430x261x) || defined(__msp430x26x)
  provides interface HplMsp430GeneralIO as DAC0;
  provides interface HplMsp430GeneralIO as DAC1;
#endif /* __msp430x261x || __msp430x26x */
#endif /* __msp430x241x || __msp430x261x || __msp430x26x */


/*
 * x5 family: cc430f513{3,5,7}
 * in particular cc4305135 and cc4305137
 */
#if defined(__cc430x513x) || defined(__cc430x612x) || defined(__cc430x613x)
  provides interface HplMsp430GeneralIO as CBOUT0;
  provides interface HplMsp430GeneralIO as TA0CLK;
  provides interface HplMsp430GeneralIO as CBOUT1;
  provides interface HplMsp430GeneralIO as TA1CLK;
  provides interface HplMsp430GeneralIO as ACLK;
  provides interface HplMsp430GeneralIO as SMCLK;
  provides interface HplMsp430GeneralIO as RTCCLK;
  provides interface HplMsp430GeneralIO as ADC12CLK;
  provides interface HplMsp430GeneralIO as DMAE0;
  provides interface HplMsp430GeneralIO as SVMOUT;
  provides interface HplMsp430GeneralIO as TA0CCR0A;
  provides interface HplMsp430GeneralIO as TA0CCR1A;
  provides interface HplMsp430GeneralIO as TA0CCR2A;
  provides interface HplMsp430GeneralIO as TA0CCR3A;
  provides interface HplMsp430GeneralIO as TA0CCR4A;
  provides interface HplMsp430GeneralIO as TA1CCR0A;
  provides interface HplMsp430GeneralIO as TA1CCR1A;
  provides interface HplMsp430GeneralIO as TA1CCR2A;
  provides interface HplMsp430GeneralIO as UCA0RXD;
  provides interface HplMsp430GeneralIO as UCA0SOMI;
  provides interface HplMsp430GeneralIO as UCA0TXD;
  provides interface HplMsp430GeneralIO as UCA0SIMO;
  provides interface HplMsp430GeneralIO as UCA0CLK;
  provides interface HplMsp430GeneralIO as UCB0STE;
  provides interface HplMsp430GeneralIO as UCB0SOMI;
  provides interface HplMsp430GeneralIO as UCB0SCL;
  provides interface HplMsp430GeneralIO as UCB0SIMO;
  provides interface HplMsp430GeneralIO as UCB0SDA;
  provides interface HplMsp430GeneralIO as UCB0CLK;
  provides interface HplMsp430GeneralIO as UCA0STE;
  provides interface HplMsp430GeneralIO as RFGDO0;
  provides interface HplMsp430GeneralIO as RFGDO1;
  provides interface HplMsp430GeneralIO as RFGDO2;

#if defined(__cc430x513x) || defined(__cc430x613x)
  provides interface HplMsp430GeneralIO as ADC0;
  provides interface HplMsp430GeneralIO as ADC1;
  provides interface HplMsp430GeneralIO as ADC2;
  provides interface HplMsp430GeneralIO as ADC3;
  provides interface HplMsp430GeneralIO as ADC4;
  provides interface HplMsp430GeneralIO as ADC5;
#if defined(__cc430x613x)
  provides interface HplMsp430GeneralIO as ADC6;
  provides interface HplMsp430GeneralIO as ADC7;
#endif /* cc430x613x */
#endif /* cc430x513x || cc430x613x */
#endif /* cc430x513x || cc430x612x || cc430x613x */


/*
 * x5 family: msp430f541{8,9}{,a}, 543{5,6,7,8}{,a}
 * in particular 5418a and 5438a
 * You should be using the A parts.   Non-A are buggy.
 */
#if defined(__msp430x54x) || defined(__msp430x54xA)
  provides interface HplMsp430GeneralIO as TA0CCR0;
  provides interface HplMsp430GeneralIO as TA0CCR1;
  provides interface HplMsp430GeneralIO as TA0CCR2;
  provides interface HplMsp430GeneralIO as TA0CCR3;
  provides interface HplMsp430GeneralIO as TA0CCR4;
  provides interface HplMsp430GeneralIO as TA0CLK;

  provides interface HplMsp430GeneralIO as TA1CCR0;
  provides interface HplMsp430GeneralIO as TA1CCR1;
  provides interface HplMsp430GeneralIO as TA1CCR2;
  provides interface HplMsp430GeneralIO as TA1CLK;

  provides interface HplMsp430GeneralIO as TB0CCR0;
  provides interface HplMsp430GeneralIO as TB0CCR1;
  provides interface HplMsp430GeneralIO as TB0CCR2;
  provides interface HplMsp430GeneralIO as TB0CCR3;
  provides interface HplMsp430GeneralIO as TB0CCR4;
  provides interface HplMsp430GeneralIO as TB0CCR5;
  provides interface HplMsp430GeneralIO as TB0CCR6;
  provides interface HplMsp430GeneralIO as TB0CLK;

  provides interface HplMsp430GeneralIO as RTCCLK;
  provides interface HplMsp430GeneralIO as MCLK;
  provides interface HplMsp430GeneralIO as SMCLK;
  provides interface HplMsp430GeneralIO as ACLK;
  provides interface HplMsp430GeneralIO as ADC12CLK;
  provides interface HplMsp430GeneralIO as DMAE0;

  provides interface HplMsp430GeneralIO as UCA0CLK;
  provides interface HplMsp430GeneralIO as UCA0STE;
  provides interface HplMsp430GeneralIO as UCA0TXD;
  provides interface HplMsp430GeneralIO as UCA0RXD;
  provides interface HplMsp430GeneralIO as UCA0SIMO;
  provides interface HplMsp430GeneralIO as UCA0SOMI;

  provides interface HplMsp430GeneralIO as UCB0CLK;
  provides interface HplMsp430GeneralIO as UCB0STE;
  provides interface HplMsp430GeneralIO as UCB0SIMO;
  provides interface HplMsp430GeneralIO as UCB0SOMI;
  provides interface HplMsp430GeneralIO as UCB0SDA;
  provides interface HplMsp430GeneralIO as UCB0SCL;

  provides interface HplMsp430GeneralIO as UCA1CLK;
  provides interface HplMsp430GeneralIO as UCA1STE;
  provides interface HplMsp430GeneralIO as UCA1TXD;
  provides interface HplMsp430GeneralIO as UCA1RXD;
  provides interface HplMsp430GeneralIO as UCA1SIMO;
  provides interface HplMsp430GeneralIO as UCA1SOMI;

  provides interface HplMsp430GeneralIO as UCB1CLK;
  provides interface HplMsp430GeneralIO as UCB1STE;
  provides interface HplMsp430GeneralIO as UCB1SIMO;
  provides interface HplMsp430GeneralIO as UCB1SOMI;
  provides interface HplMsp430GeneralIO as UCB1SDA;
  provides interface HplMsp430GeneralIO as UCB1SCL;

  provides interface HplMsp430GeneralIO as UCA2CLK;
  provides interface HplMsp430GeneralIO as UCA2STE;
  provides interface HplMsp430GeneralIO as UCA2TXD;
  provides interface HplMsp430GeneralIO as UCA2RXD;
  provides interface HplMsp430GeneralIO as UCA2SIMO;
  provides interface HplMsp430GeneralIO as UCA2SOMI;

  provides interface HplMsp430GeneralIO as UCB2CLK;
  provides interface HplMsp430GeneralIO as UCB2STE;
  provides interface HplMsp430GeneralIO as UCB2SIMO;
  provides interface HplMsp430GeneralIO as UCB2SOMI;
  provides interface HplMsp430GeneralIO as UCB2SDA;
  provides interface HplMsp430GeneralIO as UCB2SCL;

  provides interface HplMsp430GeneralIO as UCA3CLK;
  provides interface HplMsp430GeneralIO as UCA3STE;
  provides interface HplMsp430GeneralIO as UCA3TXD;
  provides interface HplMsp430GeneralIO as UCA3RXD;
  provides interface HplMsp430GeneralIO as UCA3SIMO;
  provides interface HplMsp430GeneralIO as UCA3SOMI;

  provides interface HplMsp430GeneralIO as UCB3CLK;
  provides interface HplMsp430GeneralIO as UCB3STE;
  provides interface HplMsp430GeneralIO as UCB3SIMO;
  provides interface HplMsp430GeneralIO as UCB3SOMI;
  provides interface HplMsp430GeneralIO as UCB3SDA;
  provides interface HplMsp430GeneralIO as UCB3SCL;

  provides interface HplMsp430GeneralIO as ADC0;
  provides interface HplMsp430GeneralIO as ADC1;
  provides interface HplMsp430GeneralIO as ADC2;
  provides interface HplMsp430GeneralIO as ADC3;
  provides interface HplMsp430GeneralIO as ADC4;
  provides interface HplMsp430GeneralIO as ADC5;
  provides interface HplMsp430GeneralIO as ADC6;
  provides interface HplMsp430GeneralIO as ADC7;

// A8 and A9 can either be external inputs or connected to Vref/Veref
// Check your chip for more details.

  provides interface HplMsp430GeneralIO as ADC8;
  provides interface HplMsp430GeneralIO as ADC9;

// A10 connects internally to Ref_x and A11 (INCHx = 0xB)
// measures AVcc through a divider network.   There are
// no external pins associated with ADC10 or ADC11.

  provides interface HplMsp430GeneralIO as ADC12;
  provides interface HplMsp430GeneralIO as ADC13;
  provides interface HplMsp430GeneralIO as ADC14;
  provides interface HplMsp430GeneralIO as ADC15;

#endif /* msp430x54x || msp430x54xA */

}
implementation {
  components 
#if defined(__MSP430_HAS_PORT1_R__)
    new HplMsp430GeneralIORenP(P1IN_, P1OUT_, P1DIR_, P1SEL_, P1REN_, 0) as P10,
    new HplMsp430GeneralIORenP(P1IN_, P1OUT_, P1DIR_, P1SEL_, P1REN_, 1) as P11,
    new HplMsp430GeneralIORenP(P1IN_, P1OUT_, P1DIR_, P1SEL_, P1REN_, 2) as P12,
    new HplMsp430GeneralIORenP(P1IN_, P1OUT_, P1DIR_, P1SEL_, P1REN_, 3) as P13,
    new HplMsp430GeneralIORenP(P1IN_, P1OUT_, P1DIR_, P1SEL_, P1REN_, 4) as P14,
    new HplMsp430GeneralIORenP(P1IN_, P1OUT_, P1DIR_, P1SEL_, P1REN_, 5) as P15,
    new HplMsp430GeneralIORenP(P1IN_, P1OUT_, P1DIR_, P1SEL_, P1REN_, 6) as P16,
    new HplMsp430GeneralIORenP(P1IN_, P1OUT_, P1DIR_, P1SEL_, P1REN_, 7) as P17,
#elif defined(__msp430_have_port1) || defined(__MSP430_HAS_PORT1__)
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 0) as P10,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 1) as P11,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 2) as P12,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 3) as P13,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 4) as P14,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 5) as P15,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 6) as P16,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 7) as P17,
#endif

#if defined(__MSP430_HAS_PORT2_R__)
    new HplMsp430GeneralIORenP(P2IN_, P2OUT_, P2DIR_, P2SEL_, P2REN_, 0) as P20,
    new HplMsp430GeneralIORenP(P2IN_, P2OUT_, P2DIR_, P2SEL_, P2REN_, 1) as P21,
    new HplMsp430GeneralIORenP(P2IN_, P2OUT_, P2DIR_, P2SEL_, P2REN_, 2) as P22,
    new HplMsp430GeneralIORenP(P2IN_, P2OUT_, P2DIR_, P2SEL_, P2REN_, 3) as P23,
    new HplMsp430GeneralIORenP(P2IN_, P2OUT_, P2DIR_, P2SEL_, P2REN_, 4) as P24,
    new HplMsp430GeneralIORenP(P2IN_, P2OUT_, P2DIR_, P2SEL_, P2REN_, 5) as P25,
    new HplMsp430GeneralIORenP(P2IN_, P2OUT_, P2DIR_, P2SEL_, P2REN_, 6) as P26,
    new HplMsp430GeneralIORenP(P2IN_, P2OUT_, P2DIR_, P2SEL_, P2REN_, 7) as P27,
#elif defined(__msp430_have_port2) || defined(__MSP430_HAS_PORT2__)
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 0) as P20,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 1) as P21,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 2) as P22,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 3) as P23,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 4) as P24,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 5) as P25,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 6) as P26,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 7) as P27,
#endif

#if defined(__MSP430_HAS_PORT3_R__)
    new HplMsp430GeneralIORenP(P3IN_, P3OUT_, P3DIR_, P3SEL_, P3REN_, 0) as P30,
    new HplMsp430GeneralIORenP(P3IN_, P3OUT_, P3DIR_, P3SEL_, P3REN_, 1) as P31,
    new HplMsp430GeneralIORenP(P3IN_, P3OUT_, P3DIR_, P3SEL_, P3REN_, 2) as P32,
    new HplMsp430GeneralIORenP(P3IN_, P3OUT_, P3DIR_, P3SEL_, P3REN_, 3) as P33,
    new HplMsp430GeneralIORenP(P3IN_, P3OUT_, P3DIR_, P3SEL_, P3REN_, 4) as P34,
    new HplMsp430GeneralIORenP(P3IN_, P3OUT_, P3DIR_, P3SEL_, P3REN_, 5) as P35,
    new HplMsp430GeneralIORenP(P3IN_, P3OUT_, P3DIR_, P3SEL_, P3REN_, 6) as P36,
    new HplMsp430GeneralIORenP(P3IN_, P3OUT_, P3DIR_, P3SEL_, P3REN_, 7) as P37,
#elif defined(__msp430_have_port3) || defined(__MSP430_HAS_PORT3__)
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 0) as P30,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 1) as P31,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 2) as P32,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 3) as P33,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 4) as P34,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 5) as P35,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 6) as P36,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 7) as P37,
#endif

#if defined(__MSP430_HAS_PORT4_R__)
    new HplMsp430GeneralIORenP(P4IN_, P4OUT_, P4DIR_, P4SEL_, P4REN_, 0) as P40,
    new HplMsp430GeneralIORenP(P4IN_, P4OUT_, P4DIR_, P4SEL_, P4REN_, 1) as P41,
    new HplMsp430GeneralIORenP(P4IN_, P4OUT_, P4DIR_, P4SEL_, P4REN_, 2) as P42,
    new HplMsp430GeneralIORenP(P4IN_, P4OUT_, P4DIR_, P4SEL_, P4REN_, 3) as P43,
    new HplMsp430GeneralIORenP(P4IN_, P4OUT_, P4DIR_, P4SEL_, P4REN_, 4) as P44,
    new HplMsp430GeneralIORenP(P4IN_, P4OUT_, P4DIR_, P4SEL_, P4REN_, 5) as P45,
    new HplMsp430GeneralIORenP(P4IN_, P4OUT_, P4DIR_, P4SEL_, P4REN_, 6) as P46,
    new HplMsp430GeneralIORenP(P4IN_, P4OUT_, P4DIR_, P4SEL_, P4REN_, 7) as P47,
#elif defined(__msp430_have_port4) || defined(__MSP430_HAS_PORT4__)
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 0) as P40,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 1) as P41,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 2) as P42,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 3) as P43,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 4) as P44,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 5) as P45,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 6) as P46,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 7) as P47,
#endif

#if defined(__MSP430_HAS_PORT5_R__)
    new HplMsp430GeneralIORenP(P5IN_, P5OUT_, P5DIR_, P5SEL_, P5REN_, 0) as P50,
    new HplMsp430GeneralIORenP(P5IN_, P5OUT_, P5DIR_, P5SEL_, P5REN_, 1) as P51,
    new HplMsp430GeneralIORenP(P5IN_, P5OUT_, P5DIR_, P5SEL_, P5REN_, 2) as P52,
    new HplMsp430GeneralIORenP(P5IN_, P5OUT_, P5DIR_, P5SEL_, P5REN_, 3) as P53,
    new HplMsp430GeneralIORenP(P5IN_, P5OUT_, P5DIR_, P5SEL_, P5REN_, 4) as P54,
    new HplMsp430GeneralIORenP(P5IN_, P5OUT_, P5DIR_, P5SEL_, P5REN_, 5) as P55,
    new HplMsp430GeneralIORenP(P5IN_, P5OUT_, P5DIR_, P5SEL_, P5REN_, 6) as P56,
    new HplMsp430GeneralIORenP(P5IN_, P5OUT_, P5DIR_, P5SEL_, P5REN_, 7) as P57,
#elif defined(__msp430_have_port5) || defined(__MSP430_HAS_PORT5__)
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 0) as P50,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 1) as P51,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 2) as P52,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 3) as P53,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 4) as P54,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 5) as P55,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 6) as P56,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 7) as P57,
#endif

#if defined(__MSP430_HAS_PORT6_R__)
    new HplMsp430GeneralIORenP(P6IN_, P6OUT_, P6DIR_, P6SEL_, P6REN_, 0) as P60,
    new HplMsp430GeneralIORenP(P6IN_, P6OUT_, P6DIR_, P6SEL_, P6REN_, 1) as P61,
    new HplMsp430GeneralIORenP(P6IN_, P6OUT_, P6DIR_, P6SEL_, P6REN_, 2) as P62,
    new HplMsp430GeneralIORenP(P6IN_, P6OUT_, P6DIR_, P6SEL_, P6REN_, 3) as P63,
    new HplMsp430GeneralIORenP(P6IN_, P6OUT_, P6DIR_, P6SEL_, P6REN_, 4) as P64,
    new HplMsp430GeneralIORenP(P6IN_, P6OUT_, P6DIR_, P6SEL_, P6REN_, 5) as P65,
    new HplMsp430GeneralIORenP(P6IN_, P6OUT_, P6DIR_, P6SEL_, P6REN_, 6) as P66,
    new HplMsp430GeneralIORenP(P6IN_, P6OUT_, P6DIR_, P6SEL_, P6REN_, 7) as P67,
#elif defined(__msp430_have_port6) || defined(__MSP430_HAS_PORT6__)
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 0) as P60,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 1) as P61,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 2) as P62,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 3) as P63,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 4) as P64,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 5) as P65,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 6) as P66,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 7) as P67,
#endif

#if defined(__MSP430_HAS_PORT7_R__)
    new HplMsp430GeneralIORenP(P7IN_, P7OUT_, P7DIR_, P7SEL_, P7REN_, 0) as P70,
    new HplMsp430GeneralIORenP(P7IN_, P7OUT_, P7DIR_, P7SEL_, P7REN_, 1) as P71,
    new HplMsp430GeneralIORenP(P7IN_, P7OUT_, P7DIR_, P7SEL_, P7REN_, 2) as P72,
    new HplMsp430GeneralIORenP(P7IN_, P7OUT_, P7DIR_, P7SEL_, P7REN_, 3) as P73,
    new HplMsp430GeneralIORenP(P7IN_, P7OUT_, P7DIR_, P7SEL_, P7REN_, 4) as P74,
    new HplMsp430GeneralIORenP(P7IN_, P7OUT_, P7DIR_, P7SEL_, P7REN_, 5) as P75,
    new HplMsp430GeneralIORenP(P7IN_, P7OUT_, P7DIR_, P7SEL_, P7REN_, 6) as P76,
    new HplMsp430GeneralIORenP(P7IN_, P7OUT_, P7DIR_, P7SEL_, P7REN_, 7) as P77,
#elif defined(__msp430_have_port7) || defined(__MSP430_HAS_PORT7__)
    new HplMsp430GeneralIOP(P7IN_, P7OUT_, P7DIR_, P7SEL_, 0) as P70,
    new HplMsp430GeneralIOP(P7IN_, P7OUT_, P7DIR_, P7SEL_, 1) as P71,
    new HplMsp430GeneralIOP(P7IN_, P7OUT_, P7DIR_, P7SEL_, 2) as P72,
    new HplMsp430GeneralIOP(P7IN_, P7OUT_, P7DIR_, P7SEL_, 3) as P73,
    new HplMsp430GeneralIOP(P7IN_, P7OUT_, P7DIR_, P7SEL_, 4) as P74,
    new HplMsp430GeneralIOP(P7IN_, P7OUT_, P7DIR_, P7SEL_, 5) as P75,
    new HplMsp430GeneralIOP(P7IN_, P7OUT_, P7DIR_, P7SEL_, 6) as P76,
    new HplMsp430GeneralIOP(P7IN_, P7OUT_, P7DIR_, P7SEL_, 7) as P77,
#endif

#if defined(__MSP430_HAS_PORT8_R__)
    new HplMsp430GeneralIORenP(P8IN_, P8OUT_, P8DIR_, P8SEL_, P8REN_, 0) as P80,
    new HplMsp430GeneralIORenP(P8IN_, P8OUT_, P8DIR_, P8SEL_, P8REN_, 1) as P81,
    new HplMsp430GeneralIORenP(P8IN_, P8OUT_, P8DIR_, P8SEL_, P8REN_, 2) as P82,
    new HplMsp430GeneralIORenP(P8IN_, P8OUT_, P8DIR_, P8SEL_, P8REN_, 3) as P83,
    new HplMsp430GeneralIORenP(P8IN_, P8OUT_, P8DIR_, P8SEL_, P8REN_, 4) as P84,
    new HplMsp430GeneralIORenP(P8IN_, P8OUT_, P8DIR_, P8SEL_, P8REN_, 5) as P85,
    new HplMsp430GeneralIORenP(P8IN_, P8OUT_, P8DIR_, P8SEL_, P8REN_, 6) as P86,
    new HplMsp430GeneralIORenP(P8IN_, P8OUT_, P8DIR_, P8SEL_, P8REN_, 7) as P87,
#elif defined(__msp430_have_port8) || defined(__MSP430_HAS_PORT8__)
    new HplMsp430GeneralIOP(P8IN_, P8OUT_, P8DIR_, P8SEL_, 0) as P80,
    new HplMsp430GeneralIOP(P8IN_, P8OUT_, P8DIR_, P8SEL_, 1) as P81,
    new HplMsp430GeneralIOP(P8IN_, P8OUT_, P8DIR_, P8SEL_, 2) as P82,
    new HplMsp430GeneralIOP(P8IN_, P8OUT_, P8DIR_, P8SEL_, 3) as P83,
    new HplMsp430GeneralIOP(P8IN_, P8OUT_, P8DIR_, P8SEL_, 4) as P84,
    new HplMsp430GeneralIOP(P8IN_, P8OUT_, P8DIR_, P8SEL_, 5) as P85,
    new HplMsp430GeneralIOP(P8IN_, P8OUT_, P8DIR_, P8SEL_, 6) as P86,
    new HplMsp430GeneralIOP(P8IN_, P8OUT_, P8DIR_, P8SEL_, 7) as P87,
#endif

#if defined(__MSP430_HAS_PORT9_R__)
    new HplMsp430GeneralIORenP(P9IN_, P9OUT_, P9DIR_, P9SEL_, P9REN_, 0) as P90,
    new HplMsp430GeneralIORenP(P9IN_, P9OUT_, P9DIR_, P9SEL_, P9REN_, 1) as P91,
    new HplMsp430GeneralIORenP(P9IN_, P9OUT_, P9DIR_, P9SEL_, P9REN_, 2) as P92,
    new HplMsp430GeneralIORenP(P9IN_, P9OUT_, P9DIR_, P9SEL_, P9REN_, 3) as P93,
    new HplMsp430GeneralIORenP(P9IN_, P9OUT_, P9DIR_, P9SEL_, P9REN_, 4) as P94,
    new HplMsp430GeneralIORenP(P9IN_, P9OUT_, P9DIR_, P9SEL_, P9REN_, 5) as P95,
    new HplMsp430GeneralIORenP(P9IN_, P9OUT_, P9DIR_, P9SEL_, P9REN_, 6) as P96,
    new HplMsp430GeneralIORenP(P9IN_, P9OUT_, P9DIR_, P9SEL_, P9REN_, 7) as P97,
#elif defined(__msp430_have_port9) || defined(__MSP430_HAS_PORT9__)
    new HplMsp430GeneralIOP(P9IN_, P9OUT_, P9DIR_, P9SEL_, 0) as P90,
    new HplMsp430GeneralIOP(P9IN_, P9OUT_, P9DIR_, P9SEL_, 1) as P91,
    new HplMsp430GeneralIOP(P9IN_, P9OUT_, P9DIR_, P9SEL_, 2) as P92,
    new HplMsp430GeneralIOP(P9IN_, P9OUT_, P9DIR_, P9SEL_, 3) as P93,
    new HplMsp430GeneralIOP(P9IN_, P9OUT_, P9DIR_, P9SEL_, 4) as P94,
    new HplMsp430GeneralIOP(P9IN_, P9OUT_, P9DIR_, P9SEL_, 5) as P95,
    new HplMsp430GeneralIOP(P9IN_, P9OUT_, P9DIR_, P9SEL_, 6) as P96,
    new HplMsp430GeneralIOP(P9IN_, P9OUT_, P9DIR_, P9SEL_, 7) as P97,
#endif

#if defined(__MSP430_HAS_PORT10_R__)
    new HplMsp430GeneralIORenP(P10IN_, P10OUT_, P10DIR_, P10SEL_, P10REN_, 0) as P100,
    new HplMsp430GeneralIORenP(P10IN_, P10OUT_, P10DIR_, P10SEL_, P10REN_, 1) as P101,
    new HplMsp430GeneralIORenP(P10IN_, P10OUT_, P10DIR_, P10SEL_, P10REN_, 2) as P102,
    new HplMsp430GeneralIORenP(P10IN_, P10OUT_, P10DIR_, P10SEL_, P10REN_, 3) as P103,
    new HplMsp430GeneralIORenP(P10IN_, P10OUT_, P10DIR_, P10SEL_, P10REN_, 4) as P104,
    new HplMsp430GeneralIORenP(P10IN_, P10OUT_, P10DIR_, P10SEL_, P10REN_, 5) as P105,
    new HplMsp430GeneralIORenP(P10IN_, P10OUT_, P10DIR_, P10SEL_, P10REN_, 6) as P106,
    new HplMsp430GeneralIORenP(P10IN_, P10OUT_, P10DIR_, P10SEL_, P10REN_, 7) as P107,
#elif defined(__msp430_have_port10) || defined(__MSP430_HAS_PORT10__)
    new HplMsp430GeneralIOP(P10IN_, P10OUT_, P10DIR_, P10SEL_, 0) as P100,
    new HplMsp430GeneralIOP(P10IN_, P10OUT_, P10DIR_, P10SEL_, 1) as P101,
    new HplMsp430GeneralIOP(P10IN_, P10OUT_, P10DIR_, P10SEL_, 2) as P102,
    new HplMsp430GeneralIOP(P10IN_, P10OUT_, P10DIR_, P10SEL_, 3) as P103,
    new HplMsp430GeneralIOP(P10IN_, P10OUT_, P10DIR_, P10SEL_, 4) as P104,
    new HplMsp430GeneralIOP(P10IN_, P10OUT_, P10DIR_, P10SEL_, 5) as P105,
    new HplMsp430GeneralIOP(P10IN_, P10OUT_, P10DIR_, P10SEL_, 6) as P106,
    new HplMsp430GeneralIOP(P10IN_, P10OUT_, P10DIR_, P10SEL_, 7) as P107,
#endif

#if defined(__MSP430_HAS_PORT11_R__)
    new HplMsp430GeneralIORenP(P11IN_, P11OUT_, P11DIR_, P11SEL_, P11REN_, 0) as P110,
    new HplMsp430GeneralIORenP(P11IN_, P11OUT_, P11DIR_, P11SEL_, P11REN_, 1) as P111,
    new HplMsp430GeneralIORenP(P11IN_, P11OUT_, P11DIR_, P11SEL_, P11REN_, 2) as P112,
    new HplMsp430GeneralIORenP(P11IN_, P11OUT_, P11DIR_, P11SEL_, P11REN_, 3) as P113,
    new HplMsp430GeneralIORenP(P11IN_, P11OUT_, P11DIR_, P11SEL_, P11REN_, 4) as P114,
    new HplMsp430GeneralIORenP(P11IN_, P11OUT_, P11DIR_, P11SEL_, P11REN_, 5) as P115,
    new HplMsp430GeneralIORenP(P11IN_, P11OUT_, P11DIR_, P11SEL_, P11REN_, 6) as P116,
    new HplMsp430GeneralIORenP(P11IN_, P11OUT_, P11DIR_, P11SEL_, P11REN_, 7) as P117,
#elif defined(__msp430_have_port11) || defined(__MSP430_HAS_PORT11__)
    new HplMsp430GeneralIOP(P11IN_, P11OUT_, P11DIR_, P11SEL_, 0) as P110,
    new HplMsp430GeneralIOP(P11IN_, P11OUT_, P11DIR_, P11SEL_, 1) as P111,
    new HplMsp430GeneralIOP(P11IN_, P11OUT_, P11DIR_, P11SEL_, 2) as P112,
    new HplMsp430GeneralIOP(P11IN_, P11OUT_, P11DIR_, P11SEL_, 3) as P113,
    new HplMsp430GeneralIOP(P11IN_, P11OUT_, P11DIR_, P11SEL_, 4) as P114,
    new HplMsp430GeneralIOP(P11IN_, P11OUT_, P11DIR_, P11SEL_, 5) as P115,
    new HplMsp430GeneralIOP(P11IN_, P11OUT_, P11DIR_, P11SEL_, 6) as P116,
    new HplMsp430GeneralIOP(P11IN_, P11OUT_, P11DIR_, P11SEL_, 7) as P117,
#endif

#if defined(__MSP430_HAS_PORTJ_R__)
    new HplMsp430GeneralIORenDsP(PJIN_, PJOUT_, PJDIR_, PJREN_, PJDS_, 0) as PJ0,
    new HplMsp430GeneralIORenDsP(PJIN_, PJOUT_, PJDIR_, PJREN_, PJDS_, 1) as PJ1,
    new HplMsp430GeneralIORenDsP(PJIN_, PJOUT_, PJDIR_, PJREN_, PJDS_, 2) as PJ2,
    new HplMsp430GeneralIORenDsP(PJIN_, PJOUT_, PJDIR_, PJREN_, PJDS_, 3) as PJ3,
#endif

    PlatformC; // dummy to end unknown sequence

#if defined(__msp430_have_port1) || defined(__MSP430_HAS_PORT1__) || defined(__MSP430_HAS_PORT1_R__)
  Port10 = P10;
  Port11 = P11;
  Port12 = P12;
  Port13 = P13;
  Port14 = P14;
  Port15 = P15;
  Port16 = P16;
  Port17 = P17;
#endif

#if defined(__msp430_have_port2) || defined(__MSP430_HAS_PORT2__) || defined(__MSP430_HAS_PORT2_R__)
  Port20 = P20;
  Port21 = P21;
  Port22 = P22;
  Port23 = P23;
  Port24 = P24;
  Port25 = P25;
  Port26 = P26;
  Port27 = P27;
#endif

#if defined(__msp430_have_port3) || defined(__MSP430_HAS_PORT3__) || defined(__MSP430_HAS_PORT3_R__)
  Port30 = P30;
  Port31 = P31;
  Port32 = P32;
  Port33 = P33;
  Port34 = P34;
  Port35 = P35;
  Port36 = P36;
  Port37 = P37;
#endif

#if defined(__msp430_have_port4) || defined(__MSP430_HAS_PORT4__) || defined(__MSP430_HAS_PORT4_R__)
  Port40 = P40;
  Port41 = P41;
  Port42 = P42;
  Port43 = P43;
  Port44 = P44;
  Port45 = P45;
  Port46 = P46;
  Port47 = P47;
#endif
 
#if defined(__msp430_have_port5) || defined(__MSP430_HAS_PORT5__) || defined(__MSP430_HAS_PORT5_R__)
  Port50 = P50;
  Port51 = P51;
  Port52 = P52;
  Port53 = P53;
  Port54 = P54;
  Port55 = P55;
  Port56 = P56;
  Port57 = P57;
#endif

#if defined(__msp430_have_port6) || defined(__MSP430_HAS_PORT6__) || defined(__MSP430_HAS_PORT6_R__)
  Port60 = P60;
  Port61 = P61;
  Port62 = P62;
  Port63 = P63;
  Port64 = P64;
  Port65 = P65;
  Port66 = P66;
  Port67 = P67;
#endif

#if defined(__msp430_have_port7) || defined(__MSP430_HAS_PORT7__) || defined(__MSP430_HAS_PORT7_R__)
  Port70 = P70;
  Port71 = P71;
  Port72 = P72;
  Port73 = P73;
  Port74 = P74;
  Port75 = P75;
  Port76 = P76;
  Port77 = P77;
#endif

#if defined(__msp430_have_port8) || defined(__MSP430_HAS_PORT8__) || defined(__MSP430_HAS_PORT8_R__)
  Port80 = P80;
  Port81 = P81;
  Port82 = P82;
  Port83 = P83;
  Port84 = P84;
  Port85 = P85;
  Port86 = P86;
  Port87 = P87;
#endif

#if defined(__msp430_have_port9) || defined(__MSP430_HAS_PORT9__) || defined(__MSP430_HAS_PORT9_R__)
  Port90 = P90;
  Port91 = P91;
  Port92 = P92;
  Port93 = P93;
  Port94 = P94;
  Port95 = P95;
  Port96 = P96;
  Port97 = P97;
#endif

#if defined(__msp430_have_port10) || defined(__MSP430_HAS_PORT10__) || defined(__MSP430_HAS_PORT10_R__)
  Port100 = P100;
  Port101 = P101;
  Port102 = P102;
  Port103 = P103;
  Port104 = P104;
  Port105 = P105;
  Port106 = P106;
  Port107 = P107;
#endif

#if defined(__msp430_have_port11) || defined(__MSP430_HAS_PORT11__) || defined(__MSP430_HAS_PORT11_R__)
  Port110 = P110;
  Port111 = P111;
  Port112 = P112;
  Port113 = P113;
  Port114 = P114;
  Port115 = P115;
  Port116 = P116;
  Port117 = P117;
#endif

#if defined(__msp430_have_portJ) || defined(__MSP430_HAS_PORTJ__) || defined(__MSP430_HAS_PORTJ_R__)
  PortJ0 = PJ0;
  PortJ1 = PJ1;
  PortJ2 = PJ2;
  PortJ3 = PJ3;
#endif

#ifdef __msp430x14x
  STE0 = P30;
  SIMO0 = P31;
  SOMI0 = P32;
  UCLK0 = P33;
  UTXD0 = P34;
  URXD0 = P35;

  STE1 = P50;
  SIMO1 = P51;
  SOMI1 = P52;
  UCLK1 = P53;
  UTXD1 = P36;
  URXD1 = P37;

  ADC0 = P60;
  ADC1 = P61;
  ADC2 = P62;
  ADC3 = P63;
  ADC4 = P64;
  ADC5 = P65;
  ADC6 = P66;
  ADC7 = P67;
#endif

#ifdef __msp430x16x
  STE0 = P30;
  SIMO0 = P31;
  SDA = P31;
  SOMI0 = P32;
  UCLK0 = P33;
  SCL = P33;
  UTXD0 = P34;
  URXD0 = P35;

  STE1 = P50;
  SIMO1 = P51;
  SOMI1 = P52;
  UCLK1 = P53;
  UTXD1 = P36;
  URXD1 = P37;

  ADC0 = P60;
  ADC1 = P61;
  ADC2 = P62;
  ADC3 = P63;
  ADC4 = P64;
  ADC5 = P65;
  ADC6 = P66;
  ADC7 = P67;

  DAC0 = P66;
  DAC1 = P67;

  SVSIN = P67;
  SVSOUT = P57;
#endif

#if defined(__msp430x241x) || defined(__msp430x261x) || defined(__msp430x26x)
  UCA0CLK = P30;
  UCA0STE = P33;
  UCA0TXD = P34;
  UCA0RXD = P35;
  UCA0SIMO = P34;
  UCA0SOMI = P35;

  UCB0CLK = P33;  
  UCB0STE = P30;
  UCB0SIMO = P31;
  UCB0SOMI = P32;
  UCB0SDA = P31;
  UCB0SCL = P32;

  UCA1CLK = P50;
  UCA1STE = P53;
  UCA1TXD = P36;
  UCA1RXD = P37;
  UCA1SIMO = P36;
  UCA1SOMI = P37;

  UCB1CLK = P53;
  UCB1STE = P50;
  UCB1SIMO = P51;
  UCB1SOMI = P52;
  UCB1SDA = P51;
  UCB1SCL = P52;

  ADC0 = P60;
  ADC1 = P61;
  ADC2 = P62;
  ADC3 = P63;
  ADC4 = P64;
  ADC5 = P65;
  ADC6 = P66;
  ADC7 = P67;

#if defined(__msp430x261x) || defined(__msp430x26x)
  DAC0 = P66;
  DAC1 = P67;
#endif

  SVSIN = P67;
  SVSOUT = P57;
#endif

#if defined(__cc430x513x) || defined(__cc430x612x) || defined(__cc430x613x)
  /* Terminal functions mapped to port mapping mnemonics, per data
   * sheet table 3 */
  RFGDO0 = P10;                 // default out
  RFGDO2 = P11;                 // default out
  UCB0SOMI = P12;               // default in/out
  UCB0SCL = P12;                // default in/out
  UCB0SIMO = P13;               // default in/out
  UCB0SDA = P13;                // default in/out
  UCB0CLK = P14;                // default in/out
  UCA0STE = P14;                // default in/out
  UCA0RXD = P15;                // default in/out
  UCA0SOMI = P15;               // default in/out
  UCA0TXD = P16;                // default in/out
  UCA0SIMO = P16;               // default in/out
  UCA0CLK = P17;                // default in/out
  UCB0STE = P17;                // default in/out
  CBOUT1 = P20;                 // default out
  TA1CLK = P20;                 // default in
  TA1CCR0A = P21;               // default in/out
  TA1CCR1A = P22;               // default in/out
  TA1CCR2A = P23;               // default in/out
  RTCCLK = P24;                 // default out
  SVMOUT = P25;                 // default out
  ACLK = P26;                   // default out
  ADC12CLK = P27;               // default out
  DMAE0 = P27;                  // default in
  CBOUT0 = P30;                 // default out
  TA0CLK = P30;                 // default in
  TA0CCR0A = P31;               // defalut in/out
  TA0CCR1A = P32;               // defalut in/out
  TA0CCR2A = P33;               // defalut in/out
  TA0CCR3A = P34;               // defalut in/out
  TA0CCR4A = P35;               // defalut in/out
  RFGDO1 = P36;                 // default out
  SMCLK = P37;                  // default out
  // MCLK unassigned
  // MODCLK undefined
  // ANALOG unassigned

#if defined(__cc430x513x) || defined(__cc430x613x)
  ADC0 = P20;                   // secondary
  ADC1 = P21;                   // secondary
  ADC2 = P22;                   // secondary
  ADC3 = P23;                   // secondary
  ADC4 = P24;                   // secondary
  ADC5 = P25;                   // secondary
#if defined(__cc430x613x)
  ADC6 = P26;                   // secondary
  ADC7 = P27;                   // secondary
#endif /* cc430x613x */
#endif /* cc430x513x || cc430x613x */
#endif /* cc430x513x || cc430x612x || cc430x613x */

#if defined(__msp430x54x) || defined(__msp430x54xA)

   TA0CCR0 = P11;
   TA0CCR1 = P12;
   TA0CCR2 = P13;
   TA0CCR3 = P14;
   TA0CCR4 = P15;
   TA0CLK = P10;

   TA1CCR0 = P21;
   TA1CCR1 = P22;
   TA1CCR2 = P23;
   TA1CLK = P20;

   TB0CCR0 = P40;
   TB0CCR1 = P41;
   TB0CCR2 = P42;
   TB0CCR3 = P43;
   TB0CCR4 = P44;
   TB0CCR5 = P45;
   TB0CCR6 = P46;
   TB0CLK = P47;

   RTCCLK = P24;
   MCLK = P20;
   SMCLK = P16;
   ACLK = P10;
   ADC12CLK = P27;
   DMAE0 = P27;

   UCA0TXD = P34;
   UCA0RXD = P35;
   UCA0SIMO = P34;
   UCA0SOMI = P35;
   UCA0CLK = P30;
   UCA0STE = P33;

   UCB0STE = P30;
   UCB0SIMO = P31;
   UCB0SOMI = P32;
   UCB0SDA = P31;
   UCB0SCL = P32;
   UCB0CLK = P33;

   UCA1TXD = P56;
   UCA1RXD = P57;
   UCA1SIMO = P56;
   UCA1SOMI = P57;
   UCA1CLK = P36;
   UCA1STE = P55;

   UCB1STE = P36;
   UCB1SIMO = P37;
   UCB1SOMI = P54;
   UCB1SDA = P37;
   UCB1SCL = P54;
   UCB1CLK = P55;

  UCA2CLK  = P90;
  UCA2STE  = P93;
  UCA2TXD  = P94;
  UCA2SIMO = P94;
  UCA2RXD  = P95;
  UCA2SOMI = P95;

  UCB2STE  = P90;
  UCB2SIMO = P91;
  UCB2SOMI = P92;
  UCB2CLK  = P93;
  UCB2SDA  = P91;
  UCB2SCL  = P92;

  UCA3CLK  = P100;
  UCA3STE  = P103;
  UCA3TXD  = P104;
  UCA3SIMO = P104;
  UCA3RXD  = P105;
  UCA3SOMI = P105;

  UCB3STE  = P100;
  UCB3SIMO = P101;
  UCB3SOMI = P102;
  UCB3CLK  = P103;
  UCB3SDA  = P101;
  UCB3SCL  = P102;

   ADC0 = P60;
   ADC1 = P61;
   ADC2 = P62;
   ADC3 = P63;
   ADC4 = P64;
   ADC5 = P65;
   ADC6 = P66;
   ADC7 = P67;
   ADC8 = P50;
   ADC9 = P51;

// there are no ADC's 10 and 11 according to datasheet

   ADC12 = P74;
   ADC13 = P75;
   ADC14 = P76;
   ADC15 = P77;

// Same outputs but on different pins, need to change the names if to be used
// Not complete yet

#ifdef notdef
   SMCLK = P47;
   ACLK = P110;
   MCLK = P111;
   SMCLK = P112;

   TA0CCR0 = P80;
   TA0CCR1 = P81;
   TA0CCR2 = P82;
   TA0CCR3 = P83;
   TA0CCR4 = P84;

   TA1CCR0 = P85;
   TA1CCR1 = P86;
   TA1CCR2 = P73;
#endif

#endif	/* __msp430x54x || __msp430x54xA */
}
