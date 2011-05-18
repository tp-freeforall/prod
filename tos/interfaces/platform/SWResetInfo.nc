/*
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * SWResetInfo: provide a signal indicating that a SWReset
 * is happening.
 */

interface SWResetInfo {

  /*
   * Signal that a SWReset is about to happen.   The signal is issued just
   * prior to the reset occuring.
   */
  async event void resetting();
}
