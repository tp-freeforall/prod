
module SWResetP {
  provides interface SWReset;
}

implementation {
  async command SWReset.reset() {
#if defined(__MSP430_HAS_PMM__)
    atomic {
      PMMCTL0_H = PMMPW_H;		/* open the register set for writes. */
      PMMCTL0_L |= PMMSWPOR;
      while (1) {
	nop();
      }
    }
#elif defined(__MSP430_HAS_WDT__)
    /*
     * There is another WatchDog implementation that is denoted by
     * __MSP430_HAS_WDT_A__.   We don't include that here because all
     * the cases we've looked at that have WDT_A implement the PMM module.
     */
    atomic {
      /*
       * Generate a watch dog violation.   This will force us to the reset vector
       * as if a reset has occured.  Only problem is the h/w on the cpu chip won't
       * actually be reset.  (PUC, power up clear behaviour).
       *
       * The platform initilization code can make use of SWResetInit.init to clear
       * out these pesky unreset h/w modules.
       */
      WDTCTL = 0;			/* generate a watchdog violation */
      while (1) {
	nop();
      }
    }
#else
#error SWReset needs either PMM or WDT module
#endif
}
