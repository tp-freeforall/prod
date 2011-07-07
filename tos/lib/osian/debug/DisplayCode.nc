/* Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

#include "DisplayCode.h"

/** Provide visible feedback of a specific condition, with an optional
 * value associated with the condition.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com> */
interface DisplayCode {
  /** Return the code number associated with this display. */
  async command uint8_t id ();

  /** Enable or disable display of the related code.
   *
   * @param is_enabled TRUE if code should be displayed; FALSE if it
   * should be skipped.
   */
  async command void enable (bool is_enabled);

  /** Display the code for a limited number of repetitions.
   *
   * The code is automatically disabled after that many display
   * cycles.  Note that a display cycle is by default 2 seconds long,
   * assuming no value nybbles are included.
   *
   * @param limit_count The number of display cycles.  A value of zero
   * disables the display.  The maximum number of may be as low as 15;
   * values higher than are supported are capped at the maximum.
   **/
  async command void showLimited (unsigned int limit_count);

  /** Set the width of the value display.
   *
   * The value is displayed from high nybble to low nybble.  High
   * nybbles within a byte illuminate the marker LED.  Each nybble
   * adds 2 (default) seconds to the display cycle.
   *
   * @param value_width_nyb Number of nybbles from the current value
   * to display in the LEDs. */
  async command void setValueWidth (unsigned int value_width_nyb);

  /** Set the value to be displayed along with the code.
   *
   * Only the lower portion of the value is displayed, as configured
   * by setValueWidth.
   *
   * @param value The value to be displayed. */
  async command void setValue (displayCodeValue_t value);

  /** Provide the currently configured code value.
   *
   * @return The last value stored through the value() mutator. */
  async command displayCodeValue_t getValue ();

  /** Display the code and do not return.
   *
   * This locks the MCU into doing nothing but displaying this
   * specific code.  No other codes are displayed, and control flow
   * does not return from this command.  Use this to indicate
   * catastrophic errors (the OSIAN equivalent of a kernel panic). */
  async command void lock ();
}
