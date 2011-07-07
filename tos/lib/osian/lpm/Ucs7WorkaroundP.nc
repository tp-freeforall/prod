module Ucs7WorkaroundP {
  provides {
    interface McuPowerOverride;
    interface Init;
    interface StdControl as InhibitUcs7WorkaroundControl;
  }
  uses {
    interface McuSleepEvents;
    interface StdControl as InhibitUcs7WorkaroundLowerControl;
    interface Alarm<T32khz, uint16_t> as Alarm32khz16;
  }
} implementation {

  /** Set to TRUE to inhibit the UCS7 workaround code. */
  bool inhibitUCS7_;

  command error_t InhibitUcs7WorkaroundControl.start ()
  {
    atomic inhibitUCS7_ = TRUE;
    return SUCCESS;
  }
  command error_t InhibitUcs7WorkaroundControl.stop ()
  {
    atomic inhibitUCS7_ = FALSE;
    return SUCCESS;
  }

  async event void Alarm32khz16.fired () { }

  command error_t Init.init () { return call InhibitUcs7WorkaroundLowerControl.start(); }

  /* Support for UCS7 workaround.  This chip erratum causes DCO
   * drift if the MCU is not active for at least three reference
   * count periods when coming out of LPM2 or higher.  What we'll do
   * is, if the last time we came out of sleep in such a mode isn't
   * at least that long ago, go to sleep in LPM0 instead.  This
   * relies on TA0 being active and at the same rate as REFCLK,
   * which it is.
   *
   * Validate the need for this using the LocalTime bootstrap program.
   * Errors-per-thousand should remain zero if the workaround is
   * effective, and is generally greater than 10 if not effective and
   * the erratum is present in the chip.  Alternatively, verify with
   * SerialEcho and large incoming packets.  (Disable the workaround
   * by setting the minimum active duration value below to zero.)
   *
   * NB: The current implementation means that at most 50% of the time
   * will be in a true low power mode; when the inter-wakeup duration
   * is long, a whole period will be spent in LPM0 while it would be
   * sufficient to wake up after three reference clock periods and
   * re-enter sleep at a deeper level.  To do so would require
   * configuring a timer here, which is a bit too deep in the
   * implementation.  Applications that are particularly concerned
   * about power may implement their own workaround, disabling this
   * one through the InhibitUcs7WorkaroundControl interface.
   */

  enum {
    /** UCS7 suggests waiting at least 3 reference clock periods
     * before disabling FLL. */
    MinimumFLLActiveDuration_refclk = 3
  };

  /** TA0R value at the last wake-up which re-enabled FLL */
  uint16_t fllRestart_refclk;

  async command mcu_power_t McuPowerOverride.lowestState ()
  {
    mcu_power_t rv = MSP430_POWER_LPM4;

    if (! inhibitUCS7_) {
      uint16_t now_refclk;
      uint16_t fll_active_refclk;

      atomic now_refclk = TA0R;
      if (now_refclk >= fllRestart_refclk) {
        fll_active_refclk = now_refclk - fllRestart_refclk;
      } else {
        fll_active_refclk = fllRestart_refclk - now_refclk;
      }
      if (MinimumFLLActiveDuration_refclk > fll_active_refclk) {
        rv = MSP430_POWER_LPM0;
        call Alarm32khz16.start(1);
      }
    }
    return rv;
  }

  async event void McuSleepEvents.preSleep (mcu_power_t sleep_mode) { }

  async event void McuSleepEvents.postSleep (mcu_power_t sleep_mode)
  {
    if (sleep_mode >= MSP430_POWER_LPM1) {
      atomic fllRestart_refclk = TA0R;
    }
  }
}
