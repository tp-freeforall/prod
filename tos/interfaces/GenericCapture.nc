/*
 * Copyright (c) 2013 Eric B. Decker
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
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

/**
 * Interface for microcontroller-independent capture events
 * Yet another take on a cross MCU abstraction that is intended
 * to be a superset of what different MCUs support.
 *
 * h/w event capture with and without overwrite indications
 * interrupt driven or polled.
 *
 * @author Miklos Maroti
 * @author Eric Decker
 */

#include "TinyError.h"

interface GenericCapture<size_type> {

  /**
   * capture{Rising,Falling,Both}Edges.
   *
   * enable an edge based timer capture event.
   * various flavors.
   *
   * @return TRUE if the h/w was been initilized.
   *
   * sets up the capture h/w to capture an edged event.
   * Interrupts are not turned on.  use enableInterrupt
   * to do so.  This allows setting up for a polled config.
   *
   * set{Rising,Falling,Both}Edge{,s} can be use to modify
   * which edge is used to trigger the capture after the capture
   * has been initilized.
   */

  async command error_t captureRisingEdge();
  async command error_t captureFallingEdge();
  async command error_t captureBothEdges();

  async command void    setRisingEdge();
  async command void    setFallingEdge();
  async command void    setBothEdges();


  /**
   * Fired when an capture interrupt occurs.
   *
   * Interrupt will already be acknowledged.  The Capture
   * interrupt does not need to be cleared by the user of
   * GenericCapture.   The interrupt is cleared prior to
   * the signal being generated.
   *
   * @param time        the value of the timer.
   * @param overwrite   a previous capture value was lost.
   */
  async event   void captured(size_type time, bool overwrite);


  /**
   * Disable further captures, turns off the capture logic
   */ 
  async command void disable();


  /**
   * Clear pending capture interrupt
   */
  async command void clearInterrupt();


  /**
   * enable/disable capture interrupt
   */
  async command void enableInterrupt();
  async command void disableInterrupt();


  /**
   * has the capture overflowed
   */
  async command bool overflowed();


  /**
   * clear the overflow
   */
  async command void clearOverflow();


  /**
   * has a capture occurred?
   *
   * @return    TRUE if a capture has occured.
   *            FALSE otherwise.
   */
  async command bool     test();


  /**
   * get the current capture value
   */
  async command size_type get();
}
