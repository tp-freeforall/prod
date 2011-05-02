
module WatchDogP {
  provides interface SWReset;
}

implementation {
  async command SWReset.reset() {
    atomic {
      WDTCTL = 0;
      while (1) {
	nop();
      }
    }
}
