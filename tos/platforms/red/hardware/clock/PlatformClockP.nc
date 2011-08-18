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

/**
 * Top-level initialization of anything to do with the clock
 * subsystem.
 *
 * We mostly use the standard initialization in  Msp430XV2ClockControlP,
 * except that we may or may not have an external 32kHz crystal populated.
 *
 * If the PLATFORM_MSP430_HAS_XT1 preprocessor symbol is undefined, or is defined
 * to a non-zero value, the XIN and XOUT pins are configured to their
 * XT1 function.  The code loops up to 625ms waiting for XT1
 * stability.  If stability is not achieved, the XT1 functionality is
 * disabled.  Stabilization appears to take roughly 150ms, for the one
 * sample point I have available.
 *
 * If the PLATFORM_MSP430_HAS_XT1 preprocessor symbol is defined to zero, the XT1
 * functionality is left disabled per power-up, and no start-up delay
 * is incurred.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

module PlatformClockP {
  provides interface Init;
  uses interface Init as SubInit;
} implementation {

  default command error_t SubInit.init () { }

  command error_t Init.init () {

#if defined(PLATFORM_MSP430_HAS_XT1) && (0 == PLATFORM_MSP430_HAS_XT1)
    /* Specifically told that there is no crystal.  Do nothing. */

#else /* PLATFORM_MSP430_HAS_XT1 */

    /*
     * Either we don't know whether there's a crystal, or we've been
     * told to expect one.  Configure it and see whether a stable XT1
     * can be identified.  If so, run with it; if not, restore the
     * default configuration.
     *
     * If we were told there should be a crystal present, but it
     * doesn't stabilize, this is probably an error, but can't do
     * anything about it here.
     */

    /*
     * Enable XT1, permanently, with no additional capacitance.
     *
     * @note Both 5.0 and 5.1 must be cleared in P5DIR.
     *
     * @note If the default capacitance of XCAP_3 is retained, SMCLK
     * measures 4 per-mil faster than it should.  On the SuRF
     * hardware, setting XCAP to zero appears to work.  Other values
     * may be necessary on other hardware.
     */

    P5DIR &= ~(BIT0 | BIT1);
    P5SEL |= (BIT0 | BIT1);
    UCSCTL6 &= ~(XT1OFF | XCAP_3);

    /*
     * Spin waiting for a stable signal.  This loop runs somewhere
     * between 10K and 20K times; if it gets to 65536 without success,
     * assume the crystal's absent or broken.  At the power-up DCO
     * rate of 2MHz and no crystal, the loop takes 625ms to
     * complete. 
     *
     * @note The UCS module will fall back to REFOCLK if configured
     * for LF-mode XT1 and XT1 is not stable.  It does not, however,
     * revert to XT1 upon stabilization: the UCS module documentation
     * implies that OFIFG must be cleared for this to occur.
     * Consequently, we have to wait for stabilization even if we
     * "know" a crystal is present.
     */

    {
      uint16_t ctr = 0;
      do {
        UCSCTL7 &= ~(XT1LFOFFG + DCOFFG);
        SFRIFG1 &= ~OFIFG;
      } while (++ctr && (SFRIFG1 & OFIFG));
    }

    /*
     * If the XT1 signal is still not valid, disable it; otherwise,
     * lower the power it uses.  (XT1DRIVE setting suggested by TI
     * example code.)
     */

    if (UCSCTL7 & XT1LFOFFG) {
      P5DIR |= (BIT0 | BIT1);
      P5SEL &= ~(BIT0| BIT1);
      UCSCTL6 |= XT1OFF;
    } else {
      /*
       * TI example code suggests clearing XT1DRIVE to reduce power.
       * Current measurement does not indicate any value in doing so,
       * at least not in LPM4, but it doesn't seem to hurt either.
       */
      UCSCTL6 &= ~(XT1DRIVE_3);                 // Xtal is now stable, reduce drive
    }

#endif /* PLATFORM_MSP430_HAS_XT1 */

    return call SubInit.init();
  }
}
