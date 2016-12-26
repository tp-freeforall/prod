/*
 * Copyright (c) 2013 Eric B. Decker
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
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * Define CC2520_2591 if you have 2591 h/w hooked up.
 */

#ifndef PANIC_RADIO

enum {
  __panic_radio = unique(UQ_PANIC_SUBSYS)
};

#define PANIC_RADIO __panic_radio
#endif

#include <CC2520DriverLayer.h>

/*
 * set up GPIO h/w,  gpiopolarity (26, 0f) positive polarity,
 * gpio4 and 5 are inverted.
 *
 * gpioctrl (28, 00) other options  both defaults to POR values.
 *
 * AGCCTRL1 is also platform dependent.  If we have a 2591 we want
 * to tweak it to 0x16 otherwise 0x11.  This is done manually in
 * the PlatformCC2520.powerUP.
 */
static const uint8_t reg_vals_20[] = {
  0x2a,                                 /* sfd       -> gp0 */
  0x44,                                 /* tx_active -> gp1 */
  0x21,                                 /* exc_a     -> gp2 */
  0x7e,                                 /* hgm(0)    -> gp3 */
  0x46,                                 /* !lna_pd   -> gp4 */
  0x47,                                 /* !pa_pd    -> gp5 */
  0x0f                                  /* gpiopolarity     */
                                        /* 4/5 inverted     */
};

#define REG_VALS_20_SIZE 7


#ifdef CC2520_2591
#define CC2520_AGCCTRL1_VAL 0x16
#else
#define CC2520_AGCCTRL1_VAL 0x11
#endif


module PlatformCC2520P {
  provides interface PlatformCC2520;
  uses {
    interface HplMsp430GeneralIO as P_CSN;
    interface HplMsp430GeneralIO as P_RSTN;
    interface HplMsp430GeneralIO as P_VREN;
    interface HplMsp430GeneralIO as P_GPIO0;
    interface HplMsp430GeneralIO as P_GPIO1;
    interface HplMsp430GeneralIO as P_GPIO2;
    interface HplMsp430GeneralIO as P_SO;

    interface CC2520BasicAccess;

    interface Platform;
    interface Panic;
  }
}
implementation {

  typedef enum {
    CC2520_PWR_OFF = 0,                 /* LPM2 */
    CC2520_PWR_STANDBY,                 /* LPM1 */
    CC2520_PWR_VREN,                    /* Waiting for VREN */
    CC2520_PWR_XOSC_POLL,               /* looking for XOSC to come up */
    CC2520_PWR_AM,                      /* ActiveMode, powered up */
  } cc2520_pwr_state_t;

  /*
   * If each iteration take about 150 uS, 14 gives us a timeout of about 2 ms.
   * The data sheet says the chip should power up from LPM2 in 300 uS.
   */
  enum {
    VREN_WAIT_TIME      = 150,          /* vren power up time */
    XOSC_WAIT_TIME      = 100,          /* number of uS between iterations. */
    XOSC_MAX_ITERATIONS = 10,           /* up to 1ms before we abort */
    XOSC_BUSY_WAIT_TO   = 500,          /* busy wait max wait before bail */
  };

  norace cc2520_pwr_state_t m_pwr_state;
  norace uint16_t           m_iterations;      /* used for detecting failures. */

#define __PANIC_RADIO(where, w, x, y, z) do {               \
	call Panic.panic(PANIC_RADIO, where, w, x, y, z);   \
  } while (0)


  void resistorsOff() {
    call    P_SO.resistorOff();
//  call P_GPIO5.resistorOff();
  }


  void resistorsPullDown() {
    call    P_SO.resistorPullDown();
//  call P_GPIO5.resistorPullDown();
  }


  void writePlatformRegisters() {
    call CC2520BasicAccess.writeRegBlock(0x20, (void *) reg_vals_20, REG_VALS_20_SIZE);
    call CC2520BasicAccess.writeReg(CC2520_AGCCTRL1, CC2520_AGCCTRL1_VAL);
  }


  /* ----------------- Power Control ----------------- */
  
  /*
   * powerDown: full powerdown, LPM2
   *
   * Turn off VREN which turns off internal chip power.   This
   * causes all configuration to be lost but has a power consumption
   * of 30-120 nA (yes nano).
   *
   * According to the datasheet (see pg 34, section 10.4), when the chip is
   * shutdown SO becomes an input.   To avoid powering the chip through SO
   * we tie it and all the GPIO pins a pull down.
   *
   * This may also be an issue anytime CSn is high.  But we assume that as
   * long as the chip is powered it will do something reasonable with SO as
   * long as CSn is high.  That is it will be effectively tri-stated.
   *
   * If the bus really had multiple SPI devices on it, we would only
   * do this when the bus goes idle (default owner gets control).
   *
   * Does not need to be statefull.
   *
   * For LPM2 state, we assume RESETn is 0 and VREG is 0.  The diagram
   * on pg 40 of the CC2520 datasheet (SWRS068) seems to imply that
   * going into LPM2 they want RESETn 0 and VREG 0.   But the timing
   * diagram (fig 8 on page 41) says RESETn is a don't care.   So
   * leaving it high is probably okay.
   *
   * We need to revisit what happens when the chip is in LPM2.   VREN is down
   * so we need to be careful with any input pins to the chip to avoid
   * powering the chip.   We assume since the chip is designed explicitly for
   * powered down (VREN=0, LPM2) that signals like CSn, RESETn, etc. behave
   * reasonably if in the high state.   We need to verify this.
   */
  async command void PlatformCC2520.powerDown() {
    call P_RSTN.clr();          /* assert reset */
    call P_CSN.set();           /* remove Chip Select */

    /* shut the chip down, by turning the Voltage Regulators off */
    call P_VREN.clr();            /* turn off clocks */

    /* tie pins needed to pull downs to prevent inadvertant chip power */
    resistorsPullDown();

    /* RESETn is 0, VREN 0, CSN 1,   now in LPM2 */
    /* do we also need CSN 0?   need to check    */
    m_pwr_state = CC2520_PWR_OFF;
  }


  /*
   * powerUp - bring the CC2520 into full power up (ActiveMode)
   *
   * input:     none
   * return:    uint16_t        number of uS the upper layer should wait
   *                            before calling us again.
   *
   *                            0 - means we are fully powered up
   *
   * Take CC2520 out of full powerdown.
   *
   * Assumes RESETn: 0, VREN: 0, CSN: 1, ownership of the SPI
   *
   * This code is stateful.
   */

  async command uint16_t PlatformCC2520.powerUp() {
    switch(m_pwr_state) {
      default:                          /* other states force to */
      case CC2520_PWR_OFF:              /* something reasonable  */
        /*
         * data sheet, pg 41 shows VREN going 1 and RESETN 0 coincident.
         * Does it matter?
         */
        call P_CSN.set();                   /* make sure CSN is deasserted */
        call P_RSTN.clr();                  /* make sure reset is down     */
        m_pwr_state = CC2520_PWR_VREN;
        m_iterations = 0;

        /*
         * We look to see if VREN is already set, if so assume it
         * is stable and skip VREN power up.  Fall through into
         * XOSC stablization.
         *
         * Technically VREN.getRaw() reads the input port but when
         * set up as an output, the input port gets connected to
         * the output port so we see what we are outputing.
         */
        if (call P_VREN.getRaw() == 0) {
          /*
           * VREN is off,  Turn it on and wait for it to stablize.
           */
          call P_VREN.set();                    /* turn Volt Regulators on */

          /*
           * return how long to wait for VREN to stablize.  data sheet says
           * >= 100uS, 50 additional miks isn't going to hurt anything
           * VREN_WAIT_TIME is enum'd to 150
           */
          m_iterations++;
          return VREN_WAIT_TIME;
        }

        /* fall through, VREN already on */

      case CC2520_PWR_VREN:
        call P_RSTN.set();                  /* out of reset */
        call P_CSN.clr();                   /* assert CS    */
        m_pwr_state = CC2520_PWR_XOSC_POLL;

        /* fall through to do one check to see if XOSC is already up */

      case CC2520_PWR_XOSC_POLL:
        if (call P_SO.getRaw()) {               /* XOSC stable? SO will be 1 */
          call P_CSN.set();                     /* and deassert */
          m_pwr_state = CC2520_PWR_AM;
          writePlatformRegisters();
          resistorsOff();
          return 0;
        }
        if (++m_iterations > XOSC_MAX_ITERATIONS) {
          __PANIC_RADIO(1, m_pwr_state, m_iterations, 0, 0);
          return 0;
        }
        return XOSC_WAIT_TIME;                  /* wait some more */

      case CC2520_PWR_AM:
        return 0;
    }
  }


  /*
   * sleep: put the chip into LPM1, clocks off
   *
   * This shuts down the oscillator but keeps VREN on.   This
   * will preserve internal state in the chip.  This allows for
   * faster transition into Active Mode at the cost of more
   * power consumption.
   *
   * typical power consumption in LPM1 is 175-200 uA which is roughly
   * 3 orders of magnitude (yes magnitude) more than LPM2.
   *
   * assumes we own the SPI.
   */
  async command void PlatformCC2520.sleep() {
#ifdef notdef
    /*
     * The problem is we need to first turn the RFOFF,  clean out
     * various parts of the chip and then turn XOSC off.   So shutting
     * RF down (RFOFF) in .sleep doesn't work because we need the
     * RF off before cleaning out the controlling data structures.  The
     * RFOFF has to be done by the driver.  Then we can use sleep
     * to shut down XOSC.
     *
     * We also need to modify the current power state.  This is done by
     * .sleep.
     */
    call CC2520BasicAccess.strobe(CC2520_CMD_SRFOFF);
#endif
    call CC2520BasicAccess.strobe(CC2520_CMD_SXOSCOFF);
    call CC2520BasicAccess.strobe(CC2520_CMD_SNOP);
    m_pwr_state = CC2520_PWR_STANDBY;
  }


  /*
   * bring CC2520 out of LPM1
   *
   * return non-zero if we are polling XOSC and need more
   * time.
   */
  async command uint16_t PlatformCC2520.wakeup() {
    switch(m_pwr_state) {
      default:
	__PANIC_RADIO(2, m_pwr_state, 0, 0, 0);
        return 0;

      case CC2520_PWR_STANDBY:
        call CC2520BasicAccess.strobe(CC2520_CMD_SXOSCON);
        call CC2520BasicAccess.strobe(CC2520_CMD_SNOP);
        call P_CSN.clr();                   /* assert CS */
        m_pwr_state = CC2520_PWR_XOSC_POLL;

        /* fall through to do one check to see if XOSC is already up */

      case CC2520_PWR_XOSC_POLL:
        if (call P_SO.getRaw()) {         /* XOSC stable? SO will be 1 */
          call P_CSN.set();               /* and deassert */
          m_pwr_state = CC2520_PWR_AM;
          return 0;
        }
        return XOSC_WAIT_TIME;            /* wait some more */

      case CC2520_PWR_AM:
        return 0;
    }
  }


  /*
   * reset: reset the CC2520 chip.
   */
  async command void PlatformCC2520.reset() {
    uint16_t t0, t1;

    call P_RSTN.clr();
    call P_RSTN.set();

    /* P_SO will be 1 when Xosc is stable */
    call P_CSN.clr();                   /* assert CS */
    t0 = call Platform.usecsRaw();
    while (call P_SO.getRaw()) {
      t1 = call Platform.usecsRaw();
      if (t1 - t0 > XOSC_BUSY_WAIT_TO) {
        __PANIC_RADIO(3, t0, t1, 0, 0);
        break;
      }
    }
    call P_CSN.set();               /* and deassert */
    writePlatformRegisters();       /* reinit platform dependent regs */
  }


  /*
   * setLowGain:
   * setHighGain: control HGM pin of the CC2591.
   *
   * Only applicable for combo CC2520/2591 set ups.  A nop on non-2591
   * platforms.  Still shouldn't hurt anything.
   */
  async command void PlatformCC2520.setLowGain() {
    /*
     * set HGM (gpio3) to 0, and adjust CCA threshold
     */
    call CC2520BasicAccess.writeReg(CC2520_GPIOCTRL3, 0x7e);
    call CC2520BasicAccess.writeReg(CC2520_CCACTRL0,  0xfc);
  }

  async command void PlatformCC2520.setHighGain() {
    call CC2520BasicAccess.writeReg(CC2520_GPIOCTRL3, 0x7f);
    call CC2520BasicAccess.writeReg(CC2520_CCACTRL0,  0x06);
  }


  async event void Panic.hook() { }


#ifndef REQUIRE_PLATFORM
  default async command uint32_t Platform.usecsRaw()    { return 0; }
  default async command uint32_t Platform.jiffiesRaw()  { return 0; }
#endif

#ifndef REQUIRE_PANIC
  default async command void Panic.panic(uint8_t pcode, uint8_t where, uint16_t arg0,
					 uint16_t arg1, uint16_t arg2, uint16_t arg3) { }
  default async command void  Panic.warn(uint8_t pcode, uint8_t where, uint16_t arg0,
					 uint16_t arg1, uint16_t arg2, uint16_t arg3) { }
#endif
}
