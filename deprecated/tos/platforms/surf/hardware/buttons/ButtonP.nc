/*
 * Copyright (c) 2009-2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
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

/** Implemement the Button interface for the SuRF board.
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

generic module ButtonP (bool active_high,
                        uint8_t button_id) {
  provides {
    interface Button;
  }
  uses {
    interface HplMsp430GeneralIO as ButtonPin;
    interface GpioInterrupt as ButtonInterrupt;
    interface ButtonBridge;
  }
} implementation {

  /**
   * Read the pin status, and return TRUE iff the status corresponds
   * to a pressed button.  Optionally configure the interrupts to
   * detect a change from the current state.
   */
  bool checkAndConfigure_atomic (bool set_interrupt)
  {
    bool rv = !! call ButtonPin.get();
    if (set_interrupt) {
      if (rv) {
        call ButtonInterrupt.enableFallingEdge();
      } else {
        call ButtonInterrupt.enableRisingEdge();
      }
    }
    return (!! active_high) == rv;
  }

  /** Return TRUE iff the button is currently pressed */
  bool isPressed_ () { atomic return checkAndConfigure_atomic(FALSE); }

  /** Return TRUE iff the button is enabled */
  bool isEnabled_ () { atomic return call ButtonPin.isInput(); }

  /** Enable the button.
   * @return TRUE iff the button is currently pressed */
  bool enable_ ()
  {
    atomic {
      call ButtonPin.makeInput();
      if (active_high) {
        call ButtonPin.setResistor(MSP430_PORT_RESISTOR_PULLDOWN);
      } else {
        call ButtonPin.setResistor(MSP430_PORT_RESISTOR_PULLUP);
      }
      return call ButtonBridge.initializeState(checkAndConfigure_atomic(TRUE));
    }
  }

  /** Disable the button. */
  void disable_ ()
  {
    call ButtonInterrupt.disable();
    call ButtonPin.makeOutput();
    call ButtonPin.clr();
  }

  async event void ButtonInterrupt.fired ()
  {
    bool is_pressed;

    /* Read the button state, and configure the interrupt to detect a
     * change. */
    atomic {
      is_pressed = checkAndConfigure_atomic(TRUE);
      call ButtonBridge.stateChange(is_pressed);
    }
    /* Signal the appropriate event */
    if (is_pressed) {
      signal Button.pressed();
    } else {
      signal Button.released();
    }
  }

  async event void ButtonBridge.setEnabled (bool enablep)
  {
    if (enablep) {
      enable_();
    } else {
      disable_();
    }
  }

  async command bool Button.isPressed () { return isPressed_(); }
  async command bool Button.isEnabled () { return isEnabled_(); }
  async command bool Button.enable () { return enable_(); }
  async command void Button.disable () { return disable_(); }
  default async event void Button.pressed () { }
  default async event void Button.released () { }
}

/* 
 * Local Variables:
 * mode: c
 * End:
 */
