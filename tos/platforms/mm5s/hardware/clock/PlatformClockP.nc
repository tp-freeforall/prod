/*
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

/**
 *
 * Initilization of the Clock system for the MM5 series motes.
 *
 * MM5s are based on msp430f5438 series cpus.
 *
 * The 5438 runs at 2.2V and can clock up to 18MHz.   The 5438a
 * can run at 1.8V (up to 8 MHz), and its core can be tweaked to
 * enable faster clocking.   We default to using 8MHz so allow
 * low power execution on the 5438a.
 *
 * Previous ports of TinyOS to msp430 cpus, would set the cpu to
 * clock at a power of 2 (MiHz).   This was to facilitate syncronizing
 * with the 32768 (32 KiHz) XT1 crystal.   The Timer TEP talks about
 * time in TinyOS being binary time.  1 mis (binary millisec = 1/1024)
 * is provided by TMilli and 1 uis (binary microsec = 1/1024/1024)
 * is provided by TMicro.
 *
 * It is very desireable to run the 5438a at 1.8V for power conservation
 * (the specs are quite good).  We also want to run it at 8MHz (decimal).
 * Clocking at 8MiHz is not recommended (out of spec).  It might work but
 * it is unclear how flakey behaviour would manifest.  Not recommended.
 *
 * So for power performance reasons we want to configure for 8MHz and 1.8V.
 * (Yes the 5438 is different but we are using it to simulate set up for
 * the 5438a which has the tasty power performance specs.)  Note, we ignore
 * the 5438.   It is quite buggy and has a pin for pin replacement (the 5438a)
 * that behaves mor better.   So why bother supporting the 5438.
 *
 * The TMicro timer (TA1) is run off DCOCLK/8 which yields 1us (not 1uis)
 * ticks.  However, TMilli is the long term timer that runs when the system
 * is sleeping.   It is clocked off XT1 at 32KiHz.   This is a power of 2
 * and TMilli is defined by TEP to be in terms of 1mis.
 *
 * However, this then means that TMicro is in terms of 1us and TMilli is
 * in terms of 1mis (essentially different units).  This is not a good situation.
 * It is better to be consistent in terms of units for both TMilli and TMicro.
 * The constrant is on TMicro because of the 8MHz restriction forcing 1us.
 * This argues for TMilli also being in decimal time (1ms).   This is what
 * we are doing.   Both TMilli and TMicro decimal units.
 *
 * We want the following set up to be true when we are complete:
 *
 * 8 MHz clock.    The 5438a is spec'd for a max of 8MHz when
 * running at 1.8V.  So that is what we use.  Acutally 7995392 Hz
 * (.0576% error, it'll do).
 *
 * DCOCLK -> MCLK, SMCLK.   Also drives high speed timer that
 * provides TMicro.   1us (note, decimal microsecs).  DCOCLK
 * sync'd to FLL/XT1/32KiHz.
 *
 * MCLK /1: main  cpu clock.  Off DCOCLK.
 *
 * SMCLK /1: used for timers and peripherals.  We want to run the
 * SPI (SD, GPS, subsystems, etc.) quickly and this gives us the
 * option.  Off DCOCLK.  May want to divide it down because it isn't
 * needed to be full speed.   Dividing it down should save some energy
 * because we won't be clocking downstream parts as fast.
 *
 * ACLK: 32 KiHz.   Primarily used for slow speed timer that
 * provides TMilli.
 *
 * FLL: in use and clocked off the 32 KiHz XT1 input.
 *
 * Much of the system relies on the 32KiHz XT1 xtal working correctly.
 * We bring that up first and let it stabilize.
 *
 * The code loops up to 625ms waiting for XT1 stability.  If stability
 * is not achieved, the XT1 functionality is disabled.  This should
 * cause a hcf_panic which results in writing a panic block in slow
 * mode.  Should never happen.  Famous last words (right before the
 * rocket blows up).
 *
 * Stabilization appears to take roughly 150ms.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

#define noinit	__attribute__ ((section(".noinit"))) 

uint16_t xt1_ctr;
noinit uint16_t xt1_stop;

#define XT1_DELTAS 10
uint16_t xt1_idx;
uint16_t xt1_deltas[XT1_DELTAS];
uint16_t xt1_cap;
bool cap;
uint16_t xt1_read;
uint16_t last_xt1, last_dco;

/*
 * debugging code for tracing how the FLL homes in on the
 * target frequency.   We only nab those values which change.
 */

#define STUFF_SIZE 128

noinit uint16_t ucsctl0[STUFF_SIZE];

noinit bool clear_stuff;
noinit uint16_t nxt;

void set_stuff() {
  if (clear_stuff) {
    memset(ucsctl0, 0, sizeof(ucsctl0));
    clear_stuff = 0;
    nxt = 0;
  }
  if (nxt >= STUFF_SIZE)
    nxt = 0;
  ucsctl0[nxt] = UCSCTL0;
  nxt++;
}


module PlatformClockP {
  provides interface Init;
} implementation {

  /*
   * wait_for_32K()
   *
   * The 32KiHz Xtal provides a stable low power time base for everything
   * else needing time in the system.   It drives the FLL which provides
   * syncronization for the DCO and ACLK which provides the time base
   * for low power time (TMilli).
   *
   * The h/w has provisions for detecting XT1 oscillator faults but we
   * don't know if that takes into account frequency stability.  We have
   * observed on the msp430f2618 that the XT1 oscillator takes a considerable
   * amount of time to actual home to its base frequency.   And that
   * is where we want it before we do anything else.   So we need to
   * give it time to stabilize before using it.   This should only be true
   * coming out of reset.  Anytime we reset P7.0 and P7.1 (XT1IN, XT1OUT)
   * are reset to inputs and Pin Control and this shuts down the oscillator.
   * So we need to bring it back up.
   *
   * On reset the 5438/5438a UCS is set to a configuration much like the
   * following:  (all values in hex).
   *
   * ucsctl0: 13e8 0020 101f 0000 0044 0000 c1cd 0403 0307
   *
   * dco: 13, mod: 1e, rsel: 2, flld: 1 (f_dcoclk/2), flln: 1f
   * selref: 0 (XT1CLK), fllrefdiv: 0 (f_fllrefclk/1)
   * sela: 0 (xt1clk), sels: 4 (dcoclkdiv), selm: 4 (dcoclkdiv)
   * diva = divs = divm = 0 (/1)
   * xt2off, xt1off
   *
   * xt1 is off so clocking from REFO (32KiHz), XT1 pins set to Port/In.
   * FLL is comparing 32KiHz * 32 = 1MiHz vs. dcoclk/2 => dcoclk 2MiHz
   * SMCLK, MCLK => 1MiHz.
   *
   * We wait about a second for the 32KHz to stablize.
   *
   * PWR_UP_SEC is the number of times we need to wait for
   * TimerA to cycle (16 bits) when clocked at the default
   * msp430f5438 dco (about 2MHz).
   */

#define PWR_UP_SEC 16

  uint16_t maj_xt1() {
    uint16_t a, b, c;

    a = TA0R; b = TA0R; c = TA0R;
    if (a == b) return a;
    if (a == c) return a;
    if (b == c) return b;
    while (1)
      nop();
    return 0;
  }


  void wait_for_32K() __attribute__ ((noinline)) {
    uint16_t left;

    /*
     * TA0 -> XT1 32768   (just for fun and to compare against TA1 (1uis ticker)
     * TA1 -> SMCLK/1 (should be 1uis ticker)
     */
    TA0CTL = TACLR;			// also zeros out control bits
    TA1CTL = TACLR;
    TA0CTL = TASSEL__ACLK  | MC__CONTINOUS;	//  ACLK/1, continuous
    TA1CTL = TASSEL__SMCLK | MC__CONTINOUS;	// SMCLK/1, continuous

    /*
     * wait for about a sec for the 32KHz to come up and
     * stabilize.  We are guessing that it is stable and
     * on frequency after about a second but this needs
     * to be verified.
     *
     * FIX ME.  Need to verify stability of 32KHz.  It definitely
     * has a good looking waveform but what about its frequency
     * stability.  Needs to be measured.
     *
     * One thing to try is watching successive edges (ticks, TA0R, changing
     * by one) and seeing how many TA1 (1 uis) ticks have gone by.   When it is
     * around 30-31 ticks then we are in the right neighborhood.
     *
     * We should see about PWR_UP_SEC (16) * 64Ki * 1/1024/1024 seconds which just
     * happens to majikly equal 1 second.   whew!
     */

    xt1_cap = 16;
    left = PWR_UP_SEC;
    while (1) {
      if (TA1CTL & TAIFG) {
	/*
	 * wrapped, clear IFG, and decrement major count
	 */
	TA1CTL &= ~TAIFG;
	if (--left == 0)
	  break;
	if (left <= xt1_cap) {
	  cap = TRUE;
	  xt1_cap = 0;			/* disable future capture triggers */
	  xt1_idx = 0;
	  last_xt1 = maj_xt1();
	  last_dco = TA1R;
	}
      }
      if (cap) {
	xt1_read = maj_xt1();
	if (last_xt1 == xt1_read)
	  continue;
	if (last_xt1 != xt1_read) {
	  xt1_deltas[xt1_idx++] = TA1R - last_dco;
	  last_xt1 = xt1_read;
	  last_dco = TA1R;
	  if (xt1_idx >= XT1_DELTAS) {
	    cap = FALSE;
	    nop();
	  }
	}
      }
    }
    nop();
  }


  command error_t Init.init () {
    /*
     * Enable XT1, lowest capacitance.
     *
     * XT1 pins (7.0 and 7.1) default to Pins/In.   For the XT1
     * to function these have to be swithed to Module control.
     *
     * Surf code mumbles something about P5.0 and 1 must be clear
     * in P5DIR.   Shouldn't have any effect (the pins get kicked
     * over to the Module for the Xtal and so the direction should
     * be a don't care).   Regardless we don't change the P7DIR
     * from its power up value so will be cleared (IN).
     *
     * The surf code also talks about SMCLK being 4 per-mil faster
     * if XCAP_3 is retained.  Not sure what effect XCAP setting
     * should have on SMCLK because XCAP effects the LF osc in LF mode,
     * XTS=0 (which it will be).   So a strange comment.
     *
     * Surf found XCAP=0 worked nice.  We do the same thing but it should
     * be checked.   FIXME. 
     */

    P7SEL |= (BIT0 | BIT1);
    UCSCTL6 &= ~(XT1OFF | XCAP_3);

    /*
     * From comments in Surf code.
     *
     * Spin waiting for a stable signal.  This loop runs somewhere
     * between 10K and 20K times; if it gets to 65536 without success,
     * assume the crystal's absent or broken.  At the power-up DCO
     * (RSEL: 2, DCO: 19, MOD: 27) rate of ~2MHz and no crystal, the
     * loop takes 625ms to complete.
     *
     * @note The UCS module will fall back to REFOCLK if configured
     * for LF-mode XT1 and XT1 is not stable.  It does not, however,
     * revert to XT1 upon stabilization: the UCS module documentation
     * implies that OFIFG must be cleared for this to occur.
     * Consequently, we have to wait for stabilization even if we
     * "know" a crystal is present.
     */

    /*
     * xt1_ctr is initialized to 0 and counts up, if it hits zero
     * again because it wrapped then we bail and panic.
     */
    xt1_ctr = 0;
    do {
      xt1_ctr++;
      UCSCTL7 &= ~(XT1LFOFFG | DCOFFG);
      SFRIFG1 &= ~OFIFG;
      nop();
      nop();
      if ((SFRIFG1 & OFIFG) == 0)
	break;
    } while (xt1_ctr);

    /*
     * If the XT1 signal is still not valid, disable it.
     *
     * This is a major failure as we assume we have an XT1 xtal for
     * timing stability.   Flag it and try again?
     * FIXME
     */
    if (UCSCTL7 & XT1LFOFFG) {
      P7SEL &= ~(BIT0| BIT1);
      UCSCTL6 |= XT1OFF;
      while (1)
	nop();
      return FAIL;
    }

    /*
     * XT1 up,  lower the drive as suggested by TI.
     *
     * TI example code suggests clearing XT1DRIVE to reduce power.
     * Current measurement does not indicate any value in doing so,
     * at least not in LPM4, but it doesn't seem to hurt either.
     *
     * Note: we don't ever go into LPM4,  LPM3 is required for the
     * low speed timer to run (clocked from XT1).
     */
    UCSCTL6 &= ~(XT1DRIVE_3);                 // Xtal is now stable, reduce drive

    /*
     * We are no longer faulting, but we should still wait for the frequency to
     * stabilize.   Use wait_for_32k().
     */

    wait_for_32K();

    /*
     * ACLK is to be set to XT1CLK, assumed to be 32KiHz (2^15Hz).
     * This drives TA0 for TMilli.
     *
     * We run DCO into the integrator as /1 (FLLD_0).  This also makes
     * DCOCLKDIV = DCO.  FLLN gets set to 243.   32768 * (243 + 1)
     * = 7,995,392 Hz.   The 32768 XT1 REFCLK is not divided down
     * (/1, REFDIV).
     */

    /* Disable FLL control */
    __bis_SR_register(SR_SCG0);

    /*
     * Use XT1CLK as the FLL input: if it isn't valid, the module
     * will fall back to REFOCLK.  Use FLLREFDIV value 1 (selected
     * by bits 000)
     */
    UCSCTL3 = SELREF__XT1CLK;

    /*
     * The appropriate value for DCORSEL is obtained from the DCO
     * Frequency table of the device datasheet.  Find the DCORSEL
     * value from that table where the maximum frequency with DCOx=31
     * is closest to your desired DCO frequency.   (Where did this
     * come from?)   I've chosen next range up, don't want to run out
     * of head room.
     */

    UCSCTL0 = 0x0000;		     // Set lowest possible DCOx, MODx
    UCSCTL1 = DCORSEL_4;
    UCSCTL2 = FLLD_0 + 243;
    __bic_SR_register(SR_SCG0);               // Enable the FLL control loop

    /*
     * Worst-case settling time for the DCO when the DCO range bits have been
     * changed is n x 32 x 32 x f_MCLK / f_FLL_reference. See UCS chapter in 5xx
     * UG for optimization.
     *
     * n x 32 x 32 x 8 MHz / 32,768 Hz = 256000 = MCLK cycles for DCO to settle.
     * but we don't know what n is (depends on how the FLL integrator works).
     *
     * Now this seems like a strange way to do this.   This of course assumes
     * that we are going to home on an arbritrary frequency so need to start
     * from dco:0/mod:0.  But even that doesn't make a whole boat load of sense.
     * If going to an arbritary frequency, seems to make sense to start in the
     * middle and either move up or down.
     *
     * Now that said, we have a pretty good idea of where we are going.   To take
     * into account temperature variance and dies we start below our target.  But
     * not that far.  ie.  we know we are going to ~8MHz and dco:x/mod:y is one
     * such result.   So starting ~25% below that should work just fine and greatly
     * reduces potential start up time.   This eliminates the need for the maximum
     * delay waiting for the FLL to lock in.   We can simply run, checking dco/mod
     * looking for the maximum value we allow.   Or just let it run to dco: 31, mod: 0.
     * If it hits 31 we be done.
     */

    xt1_ctr = 0;
    clear_stuff = 1;
    do {
      xt1_ctr++;
      set_stuff();
      if (xt1_ctr == xt1_stop)
	nop();
    } while (xt1_ctr);

    /*
     * Loop until DCO fault flag is cleared.  Ignore OFIFG, since it
     * incorporates XT1 and XT2 fault detection.
     *
     * But XT2 is off so shouldn't be generating a fault and XT1 better
     * be running we are assuming it drives the FLL.  Yes if it fails
     * then we auto switch over to the internal 32KiHz REFO.   But this
     * would be counter productive so looking for XT1 fault makes
     * some sense.   But it would be an error bail.  Shouldn't happen.
     */

    do {
      UCSCTL7 &= ~(XT1LFOFFG | DCOFFG);
      SFRIFG1 &= ~OFIFG;                      // Clear fault flags
    } while (UCSCTL7 & DCOFFG); // Test DCO fault flag

    /*
     * ACLK is XT1/1, 32KiHz.
     * MCLK is set to DCOCLK/1.   8 MHz
     * SMCLK is set to DCOCLK/1.  8 MHz.
     * DCO drives TA1 for TMicro and is set to provide 1us ticks.
     * ACLK  drives TA0 for TMilli.
     */
    UCSCTL4 = SELA__XT1CLK | SELS__DCOCLK | SELM__DCOCLK;
    UCSCTL5 = DIVA__1 | DIVS__1 | DIVM__1;

    /*
     * TA0 clocked off XT1, used for TMilli, 32KiHz.
     */
    TA0CTL = TASSEL__ACLK | TACLR | MC__CONTINOUS | TAIE;
    TA0R = 0;

    /*
     * TA1 clocked off SMCLK off DCO, /8, 1us tick
     */
    TA1CTL = TASSEL__SMCLK | ID__8 | TACLR | MC__CONTINOUS | TAIE;
    TA1R = 0;

    return SUCCESS;
  }
}
