/*
 * Copyright (c) 2013, Eric B. Decker
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

/**
 * PlatformCC2520P provides the interface to platform specific initilization
 * methods for the CC2520.   Supports the CC2520 and CC2520/CC2591 combination
 * (range extender).
 *
 * Handles power changes (up, down, and standby), reset of the chip and
 * some of the configuration registers (that effect what certain platform
 * specific pins are doing what).  Also handles switching in pull down
 * resistors to avoid powering the chips when powered down.
 *
 * Justification:  The TI CC2520 chip was designed to be somewhat compatible
 * in some fashion with the previous CC2420 chip.   But what this resulted in
 * is a strange chip that loses its configuration when fully powered down and
 * that includes reverting the GPIO configuration back to default.  This
 * configuration loss also occurs on RESETn being asserted.  For example,
 * GPIO0 outputs a 1 MHz clock and GPIO5 is an input that needs to be pulled
 * down to avoid excessive current consumption.
 *
 * In addition SO, which when the chip is selected (CSn 0) is driven by the
 * chip, gets turned around as an input when the chip is in reset/LPM2 (also
 * an input when CSn high).  See page 34, section 10.4.
 *
 * When the CC2520 chip is in LPM2 (fully powered down), we need pull downs
 * on the gpio and so pins to prevent any strange behaviour.   This is
 * a platform dependent thing.  This depends on which MCU is being used and how
 * things are actually connected.  This is encapsulated by PlatformCC2520
 * which hides the details and keeps it coupled to the platform specific
 * code.
 *
 * We want the driver itself to be platform independent.
 *
 * Also see tos/chips/cc2520-v2/CC2520DriverLayerP.nc for more details on
 * what the CC2520 needs.
 */

interface PlatformCC2520 {
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
   */
  async command void powerDown();


  /*
   * powerup: switch from LPM2 (powered down) to ActiveMode.
   *
   * input:     none
   * return:    uint16_t        number of uS PlatformCC2520.powerUp
   *                            is requesting the upper layer to wait
   *                            before trying again.
   *
   *                            0 - indicates CC2520 is fully powered up.
   *
   * Take the CC2520 out of full reset. go to ActiveMode.  Come
   * out of reset and turn on XOSC.  Note: the CC2520 automatically starts
   * XOSC when the resetN pin is used.
   *
   * Does not reinitialize any registers.  Main driver has the
   * data needed to handle the initilization.
   */
  async command uint16_t powerUp();


  /*
   * sleep: put the CC2520 into LPM1
   *
   * Assumes Active Mode.  Main driver needs to make sure the radio
   * is idle before calling sleep.  Turns off XOSC.
   */
  async command void sleep();


  /**
   * wakeup: wake the CC2520 from sleep
   *
   * input:     none
   * return:    uint16_t        number of uS PlatformCC2520.powerUp
   *                            is requesting the upper layer to wait
   *                            before trying again.
   *
   *                            0 - indicates CC2520 is fully powered up.
   *
   * Assumes LPM1.  Turns XOSC on and waits for it to stablize.  But if
   * OFF will call powerUp.
   */
  async command uint16_t wakeup();


  /**
   * reset: reset the CC2520
   *
   * First, will reset the CC2520.  However, reset causes the chip to
   * lose its configuration (reset back to POR values) which changes
   * the gpio settings.
   *
   * This routine is also responsible for switching the gpio settings
   * back to something more reasonable.
   */
  async command void reset();


  /*
   * setHighGain: set high or low gain mode.
   *
   * the CC2520/CC2591 combination can be run in high or low gain mode
   * which is determined by the HGM pin on the 2591.
   *
   * some configurations wire HGM to a CC2520 gpio pin (GPIO3) and use
   * SPI traffic to the CC2520 to set the pin to a 1 or a 0.  This is
   * lame but supports existing development modules.  The TI CC2520-CC2591EM,
   * and LSR ProFLEX01-R2 modules are examples of implementations that
   * control HGM via the CC2520 GPIO3 pin.
   *
   * Other configurations, wire HGM directly to a MCU pin which frees
   * up GPIO3 for other uses such as another EXCEPTION channel.
   *
   * Any way you slice it, its platform dependent.
   */
  async command void setLowGain();
  async command void setHighGain();
}
