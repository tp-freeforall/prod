/*
 * Copyright (c) 2010 People Power Co.
 * All rights reserved.
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
 */
 
/** An interface to control a single LED.
 *
 * Provides the ability to turn on, turn off, and toggle an LED.
 *
 * Implementations of this interface are provided by the LedC
 * component, both as positional names (Led0) and by color (Green).
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com> */

interface Led {
  /** Turn the LED on.
   * Cancels any active blink or glow configuration. */
  async command void on ();

  /** Turn the LED off.
   * Cancels any active blink or glow configuration. */
  async command void off ();

  /** Turn the LED on or off, depending on parameter.
   * @param turn_on if TRUE, turn LED on; otherwise turn LED off */
  async command void set (bool turn_on);

  /** Toggle the LED.
   * Cancels any active blink or glow configuration. */
  async command void toggle ();

#if 0
  /* These functions are disabled until it is determined whether they
   * should be supported in Led or by a pulse-width-modulation
   * component that ties directly to the LED pins. */

/* Optionally provides the ability to blink the LED at a given rate.
 * Optionally provides the ability to make the LED glow (pulse-width
 * modulation).  With appropriate hardware support, the blink or glow
 * functionality may be available in certain low power modes.
 *
 * Not all LEDs on a platform may support the blink and glow
 * functionality, and there may be constraints affecting the behavior
 * of multiple LEDs placed in these modes.
 */

  /** Cause the LED to blink at the given rate.
   *
   * @param toggle_hz If positive, the rate, in hertz, at which the
   * LED should toggle.  If negative, the duration of a toggle in
   * seconds.  For example, a value of 4 indicates four toggles (two
   * on periods) per second; a value of -2 indicates an on duration of
   * two seconds followed by an off duration of two seconds.
   *
   * @return FAIL if the blink support is unavailable; otherwise
   * SUCCESS.
   */
  async command error_t blink (int toggle_rate);

  /** Cause the LED to glow using pulse-width modulation.
   *
   * @param period_32k The period of the waveform that forms the basis
   * of the cycle, in units of 32KHz.
   *
   * @param duty_cycle_32k The pulse (on) duration.  Must not exceed
   * period_32k.
   *
   * @return FAIL if glow support is unavailable; otherwise SUCCESS.
   */
  async command error_t glow (unsigned int period_32k,
                              unsigned int duty_cycle_32k);
  
#endif
}

/* 
 * Local Variables:
 * mode: c
 * End:
 */
