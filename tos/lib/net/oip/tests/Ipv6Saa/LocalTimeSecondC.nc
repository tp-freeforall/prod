/** Pseudo implementation that we can control.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
module LocalTimeSecondC {
  provides {
    interface LocalTime<TSecond>;
    interface GetSet<uint32_t>;
  }
} implementation {
  uint32_t now__;
  async command uint32_t LocalTime.get () { atomic return now__; }
  command uint32_t GetSet.get () { atomic return now__; }
  command void GetSet.set (uint32_t now) { atomic now__ = now; }
}
