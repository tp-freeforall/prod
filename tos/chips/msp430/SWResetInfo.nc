/*
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * SWResetInfo: provide a signal indicating that a SWReset
 * is happening.
 */

interface SWResetInfo {
  async event void resetting();
}
