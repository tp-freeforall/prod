/*
 * Copyright (c) 2012, 2016, 2017-2018, 2020 Eric B. Decker
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

/*
 * Platform: low level platform interface.
 *
 * The Platform interface is intended to present certain core h/w resources
 * in an easy to use fashion.
 *
 * Examples include:
 *
 *   o a low level us ticker that can be used for timeouts and instrumentation
 *     BusyWait doesn't work because you typically want to check for some
 *     terminating condition in the timing loop.
 *   o a low level jiffy ticker that is tied to an underlying long term
 *     ticker.  Typically this is a 32KiHz crystal based low power ticker.
 *   o a mechanism to turn on and off unaligned traps.
 */

interface Platform {
  /*
   * Platform provided timing.
   *
   * localTime: 32 bits of ms (mis or ms) provided by the platform
   *    for time stamps (trace or debug).
   *
   * usecsRaw: micro sec timing provided by the platform.
   *
   * jiffiesRaw: 32KiHz (or other platform dependent timing)
   *    timing provided by the platfrom.
   */

  async command uint32_t localTime();

  /*
   * platforms provide a low level usec timing element.
   * usecsRaw returns a raw value for this timing element.
   * This is used in low level time outs that are time based.
   *
   * Underlying h/w could be smaller than 32 bits.  Typically
   * if the recepient is smaller the return value will be truncated
   * to the size of the recepient, which is typically what you
   * want.
   *
   * "Size" returns number of bits implemented if you care.
   */
  async command uint32_t usecsRaw();
  async command uint32_t usecsRawSize();

  /*
   * usecsExpired: check for raw time expired.  Low level.
   *
   * input:  t_base     base time in microsecs
   *         limit      limit in usecs that should be checked.
   *
   * output: uint32_t   0 if not expired
   *                    current time in usecs if expired.
   *
   * usecsExpired will use Platform.usecsRaw() to obtain the current time
   * in usecs.  This number will be compared to t_base and if t_new-t_base
   * > limit it will return t_new indicating expiration.   If not
   * expired it will return 0.
   */
  async command uint32_t usecsExpired(uint32_t t_base, uint32_t limit);


  /*
   * platforms provide a longer term timing element.
   *
   * typically 32768 Hz (32 KiHz).  For lack of a better name
   * call it jiffies.  Note.   Existing code calls these ticks
   * jiffies already.
   *
   * Underlying h/w could be smaller than 32 bits.  "Size" returns
   * number of bits implemented if you care.
   */
  async command uint32_t jiffiesRaw();
  async command uint32_t jiffiesRawSize();


  /*
   * jiffiesExpired: check for raw time expired.  Low level.
   *
   * input:  t_base     base time in jiffies
   *         limit      limit in jiffies that should be checked.
   *
   * output: uint32_t   0 if not expired
   *                    current time in jiffies if expired.
   *
   * jiffiesExpired will use Platform.jiffiesRaw() to obtain the current time
   * in jiffies.  This number will be compared to t_base and if t_new-t_base
   * > limit it will return t_new indicating expiration.   If not
   * expired it will return 0.
   */
  async command uint32_t jiffiesExpired(uint32_t t_base, uint32_t limit);


  /*
   * depending on what cpu a platform is using, it may or may not
   * implement unaligned traps.  ie unaligned data references.
   *
   * For example, an ARM Cortex-M4F implements unaligned traps
   * and this is useful to make sure the memory is being used efficiently.
   *
   * But under certain circumstances one may want to turn these off.
   */

  /*
   * set_unaligned_traps: set state of unaligned traps
   *
   * input:   bool      TRUE  set unaligned_traps on
   *                    FALSE turn unaligned_traps off
   *
   * returns: bool      previous state of unaligned traps.
   *                    TRUE  unaligned traps were on
   *                    FALSE unaligned traps were off
   */

  async command bool set_unaligned_traps(bool on_off);


  /************************************************************************
   *
   * Platform configuration
   *
   * o Interrupt priority assignment.
   *   modern computer hardware allows the assignment of different priorities
   *   to interrupt sources.  This is inherently a platform thing.
   */

  async command int getIntPriority(int irq_number);

  /**
   * Platform dependent node id.
   *
   * Get a Platform defined node id.  This will typically be a serial number
   * or mac address.
   *
   * Platform define PLATFORM_SERIAL_NUM_SIZE determines the
   * size.  If not defined defaults to 4 bytes (uint32_t).  But platforms
   * really should define it to be clear.  (see platform.h)
   *
   * input:  *lenp      pointer where to place the length of the number.
   *
   * output: *lenp      length filled in if non-null.
   * return: *uint8_t   pointer to the serial_num or NULL.
   *
   * a Node Id is assumed to be a sequence of bytes starting with the
   * msb first.
   */
  async command uint8_t *node_id(unsigned int *lenp);
}
