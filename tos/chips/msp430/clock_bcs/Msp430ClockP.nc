/*
 * Copyright (c) 2010-2011 Eric B. Decker
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
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author Vlado Handziski <handzisk@tkn.tu-berlind.de>
 * @author Xavier Orduna <xorduna@dexmatech.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */


/***************************************************************************
 *
 * Perform basic initilization of the clock subsystem on a msp430 (x1, 1611,
 * basic_clock) or msp430X (x2, 26xx, basic_clock+, bc2).  The clock systems
 * on the x1 and x2 devices are similar enough to be supported by the same
 * driver.  x5 devices use a different system, the Unified Clock System.
 *
 * TinyOS assumes a 1 uis (us) ticker and a 32 KiHZ (30.5 us) ticker.  The
 * later is used for timing when sleeping.  On the x1 and x2 processors, the
 * 1 uis ticker (micro) is implemented by TimerA and the 32 KiHZ ticker is
 * on TimerB.
 *
 * The basic_clock system provides a main clock (DCO) used to clock the
 * CPU (MCLK).  Peripherals (timers, usci, uart, spi, i2c, etc)
 * are driven off SMCLK (sub-main), driven off DCO via a divider network.
 * TimerA is clocked off SMCLK and needs to be set to provide a 1uis (1us)
 * ticker.
 *
 * The include file Msp430DcoSpec.h determines how the clock system should
 * be set up.   Selectors in this file determine the configuration.
 *
 * TARGET_DCO_HZ: Base DCO frequency.
 * SMCLK_DIV:	  SMCLK divider.   SMCLK = DCO/(SMCLK_DIV).
 * TIMERA_DIV:	  determines the SMCLK divider for TimerA.
 *
 * Default settings:
 *
 * CPU clock: DCO 4MiHZ, (MCLK = DCO/1)
 * SMCLK:     DCO/4 (1MiHZ).
 * TimerA:    1uis (1MiHZ), SMCLK/1
 * Default Bauds: based on SMCLK 1MiHZ.
 *
 * 4 MiHZ is chosen for low power reasons.  Other processors support higher
 * speeds but defaulting to 4 MiHZ simplifies a number of things.
 *
 * The x1 processors are spec'd by TI as having a max speed of 8MHz.  TinyOS
 * is spec'd as using binary time (see TEP102).  So the simplest set up is
 * to set the x1 clock to 4 MiHZ (4194304 HZ) while 8 MiHZ (8388608) exceeds
 * the maximum clock speed as spec'd by TI.   Not a good idea.
 *
 * x2 processors can be clocked up to 16 MHZ, so running at 8 MiHZ would work.
 * A default of 4 MiHZ is chosen for lower power and to have a single main
 * clock speed.
 *
 * We also want to have a single set of baud rates as the default.   This
 * requires having a default SMCLK frequency.   We default to 1 MiHZ.
 *
 * ACLK (Aux Clk) is assumed to be run off the LFXT interface (low-freq) at
 * 32KiHz (32768).  This clock is used to calibrate the main DCO clock and
 * serves as the timer source for TB, the long term timer when sleeping.
 *
 * MCLK (Main Clk) is run off the DCO and is calibrated to 32KiHz (32768)
 * crystal (ACLK).  DCO/1.
 *
 * SMCLK (sub-main clock) is run directly off the DCO (FREQ).  DCO/(SMCLK_DIV).
 * All peripherals are run off the SMCLK.  The default should be 1MiHZ.  Default
 * baud rate setting are provided assuming this 1 MiHZ SMCLK setting.
 *
 * TimerA is programmed for a 1uis tick and is SMCLK/(TIMERA_DIV).  TIMERA_DIV can
 * be a maximum of 8 on x1 or x2 procs.  If MCLK is clocked faster than 8 MiHz
 * either SMCLK can become DCO/2 (which slows the peripherals down) or the timer
 * subsystem is changed to deal with a 512ns tick.
 *
 * TimerB is run off the 32KiHz crystal oscillator.  This is used to provide
 * a stable time base for syncronizing the main DCO clock.  It also provides
 * a stable timer that runs the timer system especially when the cpu is
 * sleeping.
 *
 * XT2 isn't used for an external oscillator because it is expensive and a power
 * hog.  It also takes a long time (measured ~5ms) to power up and stabilize.
 * You don't want to be doing that if one is putting the cpu to sleep a bunch
 * (which is needed for low power).
 *
 * WARNING: This module assumes that the 32KiHz XTAL has stablized.  This
 * is assumed to have been performed in Platform Initilization.
 *
 * The Platform code gets executed on the way up and so certain assumptions can
 * be made about the state of clocking system.  Otherwise we have to put the
 * clocks into a known state and stabilize the 32KiHz.   Once done we can just
 * proceed here with calibration of the main DCO.
 *
 * We may want to revisit this later and move wait_for_32K into this module but
 * it needs to be thought through better and what the ramifications are.  Placing
 * wait_for_32k into the startup code in Platform is safe.   It just has the
 * downside of having to put into each different platform startup when new platforms
 * are added.
 */

/*
 * Msp430DcoSpec provides cpu/platform data about clock speed.
 *
 * TARGET_DCO_HZ:	DCO frequency
 * ACLK_HZ:		Auxiliary clock frequency
 * SMCLK_DIV:		Divisor for SMCLK
 * TIMERA_DIV:		Divisor for TimerA
 *
 * TimerA will be DCO/SMCLK_DIV/TIMERA_DIV and should be set for 1MiHZ or 1MHZ.
 *
 * Suggested set up (if in doubt):
 *
 * TARGET_DCO_HZ  4194304UL
 * ACLK_HZ        32768UL
 * SMCLK_DIV      4
 * TIMERA_DIV     1
 */

#include "Msp430DcoSpec.h"
#include "Msp430Timer.h"

/*
 * Basic Clock and BC2 differ in the size of the Range Select (RSEL)
 * field.   x1xxx (BASIC_CLOCK) has 3 bits, x2xxx (BC2) has 4 bits.
 * RSEL_MAX denotes where to start for calibration, RSEL_MASK is used
 * to mask the entire RSEL field.
 */
#if defined(__MSP430_HAS_BC2__)
#define RSEL_MASK (RSEL0 | RSEL1 | RSEL2 | RSEL3)
#define RSEL_MAX RSEL3
#elif defined(__MSP430_HAS_BASIC_CLOCK__)
#define RSEL_MASK (RSEL0 | RSEL1 | RSEL2)
#define RSEL_MAX RSEL2
#else
#error "Msp430ClockP (clock_bcs): processor doesn't support BASIC_CLOCK/BC2"
#endif

#ifndef SMCLK_DIV
#error "ClockP: SMCLK_DIV needs to be defined."
#endif

#if     SMCLK_DIV == 1
#define SMCLK_DIVS DIVS_0
#elif   SMCLK_DIV == 2
#define SMCLK_DIVS DIVS_1
#elif   SMCLK_DIV == 4
#define SMCLK_DIVS DIVS_2
#elif   SMCLK_DIV == 8
#define SMCLK_DIVS DIVS_3
#else
#error "ClockP: unknown SMCLK_DIV defined.  Need valid SMCLK_DIV to proceed."
#endif

#ifndef TIMERA_DIV
#error "ClockP: TIMERA_DIV needs to be defined."
#endif

/* TA clock is DCO/SMCLK_DIV/TIMERA_DIV */
#if     TIMERA_DIV == 1
#define TIMERA_ID ID_0
#elif   TIMERA_DIV == 2
#define TIMERA_ID ID_1
#elif   TIMERA_DIV == 4
#define TIMERA_ID ID_2
#elif   TIMERA_DIV == 8
#define TIMERA_ID ID_3
#else
#error "ClockP: unknown TIMERA_DIV defined.  Need valid TIMERA_DIV to proceed."
#endif

module Msp430ClockP @safe() {
  provides {
    interface Init;
    interface Msp430ClockInit;
    interface McuPowerOverride;
  }
}

implementation {
  MSP430REG_NORACE(IE1);
  MSP430REG_NORACE(TACTL);
  MSP430REG_NORACE(TAIV);
  MSP430REG_NORACE(TBCTL);
  MSP430REG_NORACE(TBIV);

  /*
   * TI provides DCO calibration information assuming decimal Hz.  This is reflected
   * in the baud rate tables for the UART speeds as well as the DCO clock values.
   * The x5 series documentation provides both binary and decimal values.
   *
   * TinyOS defines its clocking using binary values.  TEP 102 plus it make sense
   * (synchronizing with the 32768 Hz crystal)
   */
  enum {
    ACLK_CALIB_PERIOD = 8,
    TARGET_DCO_DELTA = (TARGET_DCO_HZ / ACLK_HZ) * ACLK_CALIB_PERIOD,
  };

  async command mcu_power_t McuPowerOverride.lowestState() {
    return MSP430_POWER_LPM3;
  }

  command void Msp430ClockInit.defaultSetupDcoCalibrate() {
    TACTL   = TASSEL_2 | MC_2;		// SMCLK/1, continuous mode, all else 0
    TBCTL   = TBSSEL_1 | MC_2;		// ACLK/1,  continuous

    /*
     * x1 chips have an extra bit XT5V (same as RSEL3) in BCSCTL1 which is
     * required to be 0'd.  Given that the x1 RSEL_MAX is RSEL2 this isn't
     * a problem.
     *
     * calibrate changes just RSEL in BCSCTL1.  Other bits get set here.
     */
    BCSCTL1 = XT2OFF   | RSEL_MAX;	// set highest RSEL bit to start
    BCSCTL2 = 0;
    TBCCTL0 = CM_1;			// CM = 1, rising edge

    /*
     * leave BCSCTL3 alone, resets to 0x05,
     * XCAP 01, 6pF, LFXT1OF (XT1 osc fault)
     */
  }
    
  command void Msp430ClockInit.defaultInitClocks() {
    // BCSCTL1
    // .XT2OFF = 1;	disable the external oscillator for SCLK and MCLK
    // .XTS    = 0;	set low frequency mode for LXFT1
    // .DIVA   = 0;	set the divisor on ACLK to 1
    // .RSEL		do not modify (3 or 4 bits), XT5V is 0 if present
    BCSCTL1 = XT2OFF | (BCSCTL1 & RSEL_MASK);

    // BCSCTL2
    // .SELM = 0;	select DCOCLK as source for MCLK
    // .DIVM = 0;	set the divisor of MCLK to 1
    // .SELS = 0;	select DCOCLK as source for SMCLK
    // .DIVS = xxx;	set the divisor of SCLK to SMCLK_DIVS
    // .DCOR = 0;	select internal resistor for DCO
    BCSCTL2 = SMCLK_DIVS;

    // BCSCTL3: use default, on reset set to 4, 6pF.

    // IE1.OFIE = 0; no interrupt for oscillator fault
    CLR_FLAG( IE1, OFIE );
  }

  command void Msp430ClockInit.defaultInitTimerA() {
    TAR = 0;

    // TACTL
    // .TASSEL = 2;	source SMCLK = DCO/1
    // .ID = TIMERA_ID;	input divisor for 1uis ticks.
    // .MC = 0;		initially disabled
    // .TACLR = 0;
    // .TAIE = 1;	enable timer A interrupts
    TACTL = TASSEL_2 | TIMERA_ID | TAIE;
  }

  command void Msp430ClockInit.defaultInitTimerB() {
    TBR = 0;

    // TBCTL
    // .TBCLGRP = 0;	each TBCL group latched independently
    // .CNTL = 0;	16-bit counter
    // .TBSSEL = 1;	source ACLK
    // .ID = 0;		input divisor of 1
    // .MC = 0;		initially disabled
    // .TBCLR = 0;
    // .TBIE = 1;	enable timer B interrupts
    TBCTL = TBSSEL_1 | TBIE;
  }

  default event void Msp430ClockInit.setupDcoCalibrate() {
    call Msp430ClockInit.defaultSetupDcoCalibrate();
  }
  
  default event void Msp430ClockInit.initClocks() {
    call Msp430ClockInit.defaultInitClocks();
  }

  default event void Msp430ClockInit.initTimerA() {
    call Msp430ClockInit.defaultInitTimerA();
  }

  default event void Msp430ClockInit.initTimerB() {
    call Msp430ClockInit.defaultInitTimerB();
  }

  void startTimerA() {
    // TACTL.MC = 2; continuous mode
    TACTL = MC_2 | (TACTL & ~(MC1 | MC0));
  }

  void stopTimerA() {
    // TACTL.MC = 0; stop timer A
    TACTL = TACTL & ~(MC1|MC0);
  }

  void startTimerB() {
    // TBCTL.MC = 2; continuous mode
    TBCTL = MC_2 | (TBCTL & ~(MC1|MC0));
  }

  void stopTimerB() {
    //TBCTL.MC = 0; stop timer B
    TBCTL = TBCTL & ~(MC1|MC0);
  }

  /*
   * dco calibration.
   *
   * dco calibration is done by looking at how many dco clocks via timerA fit
   * into some number of 32768 ACLK periods.  Since we don't know where in a
   * ACLK cycle we are, we must run two cycles.  The 2nd cycle is when we
   * actually do the measurement.
   *
   * Controls for the algorithm behaviour are:
   *
   * From tos/chips/msp430/xxxxx/Msp430DcoSpec.h (or platform override):
   *	TARGET_DCO_HZ		target dco frequency
   *	ACLK_HZ			frequency of ACLK, 32768 Hz
   *
   *    ACLK_CALIB_PERIOD = 8,	how many aclk cycles to use for sample period.
   *    TARGET_DCO_DELTA	how many dco (ta) cycles we should see if
   *				calibrated.
   *
   * A calib control cell is passed around to control the algorithm.  This
   * control cell is the concatenation of RSEL (3/4 bits), DCOx (3 bits), and
   * MODx (5 bits).   Top byte contains RSEL, lower byte DCO and MOD.
   *
   * The key that drives this algorithm is TARGET_DCO_DELTA.  This is the value
   * we look for in a given ACLK_CALIB_PERIOD.  It is computed from
   * TARGET_DCO_HZ and ACLK_HZ.
   *
   * DCOCTL is the same for x1 and x2 clock systems.   x2 processors have a 4 bit
   * RSEL in BCSCTL1.
   */

  void set_dco_calib(uint16_t calib) {
    BCSCTL1 = (BCSCTL1 & ~RSEL_MASK) | ((calib >> 8) & RSEL_MASK);
    DCOCTL  = calib & 0xff;
  }

  uint16_t test_calib_busywait_delta(uint16_t calib) {
    uint16_t aclk_count = 2;		/* better code */
    uint16_t dco_prev   = 0;
    uint16_t dco_curr   = 0;

    set_dco_calib(calib);

    /*
     * Don't know where in the current 32Khz cycle we are so we run two
     * cycles.
     */
    while (aclk_count-- > 0) {
      TBCCR0 = TBR + ACLK_CALIB_PERIOD;		// set next interrupt
      TBCCTL0 &= ~CCIFG;			// clear pending interrupt
      while((TBCCTL0 & CCIFG) == 0) {		// busy wait
      }
      dco_prev = dco_curr;
      dco_curr = TAR;
    }
    return dco_curr - dco_prev;
  }

  /*
   * busyCalibrateDCO
   *
   * With ACLK_CALIB_PERIOD of 8, takes ~6ms to calibrate.
   * This is only dependent on ACLK_CALIB_PERIOD and the clock rate of ACLK
   * which is most likely 32768.
   *
   * Tested for freqs >= 1MHz (1000000).  Does not seems to work for low
   * frequencies.  Probably because the counts aren't big enough.  But we
   * don't care.  4MHz is good, 8Mhz is good.  16MHz not tested yet.
   *
   * Returns with DCOCTL and BCSCTL1 set with appropriate values of DCO/MOD
   * and RSEL.
   */
  void busyCalibrateDco() {
    uint16_t calib;
    uint16_t step;

    /*
     * Binary search for RSEL,DCO,DCOMOD.
     * It's okay that RSEL isn't monotonic.
     *
     * RSEL_MAX is 8 for the 2618 and 4 for the 1611.  So step starts
     * with either 0x0800 or 0x0400.
     */
    for (calib = 0, step = RSEL_MAX << 8; step; step >>= 1) {
      /* if the step is not past the target, keep it */
      if (test_calib_busywait_delta(calib | step) <= TARGET_DCO_DELTA)
        calib |= step;
      /*
       * if dco is 7 then mod bits remain zero they don't do anything if
       * dco is 7.  stop.
       */
      if ((calib & 0xe0) == 0xe0)
	break;
    }
    set_dco_calib(calib);
  }

  command error_t Init.init() {
    TACTL = TACLR;			/* clear should wack the IVs */
    TBCTL = TBCLR;			/* also IVs are read-only */

    atomic {
      signal Msp430ClockInit.setupDcoCalibrate();
      busyCalibrateDco();
      signal Msp430ClockInit.initClocks();
      signal Msp430ClockInit.initTimerA();
      signal Msp430ClockInit.initTimerB();
      startTimerA();
      startTimerB();
    }
    return SUCCESS;
  }
}
