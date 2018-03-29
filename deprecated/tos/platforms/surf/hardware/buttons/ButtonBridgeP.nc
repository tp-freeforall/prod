/*
 * Copyright (c) 2010 People Power Co.
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

/** Bridge the async/sync gap for legacy button notification.
 *
 * Though TinyOS has not previously provided a button interface
 * supported by all platforms, the common flavor seems to be to define
 * a UserButtonC component which provides a Get interface to read
 * button state, and a Notify interface to enable buttons and detect
 * changes in state.  Unfortunately, both these interfaces are
 * synchronous.
 *
 * The OSIAN Button interface is asynchronous, because this allows it
 * to be used in development to simulate async events and to define
 * the order of those events.  Supporting the legacy interface
 * requires a mechanism to convert those async events into non-async
 * Get and Notify.
 *
 * This component supports that translation for up to eight buttons,
 * by caching an abstraction of the async events and posting a task
 * which re-generates them in synchronous context.  Multiple async
 * events may occur before the task fires.  If a button changes state
 * at least once, at least one synchronous event will be generated.
 * If a button changes state multiple times, the events will be
 * collapsed so either one (if the end result is a change in state) or
 * two (if the end result is the same state) events are generated.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

module ButtonBridgeP {
  provides {
    interface Get<button_state_t>[uint8_t button_id];
    interface Notify<button_state_t>[uint8_t button_id];
    interface ButtonBridge[uint8_t button_id];
  }
} implementation {

  /** Indicate the state of enabled buttons on completion of the last
   * state management task.  When button i is enabled, bit i is set
   * iff button i was in pressed state.  The bit for disabled buttons
   * is undefined. */
  uint8_t lastState_;

  /** Latched set of buttons that changed state since the last task
   * execution. */
  uint8_t changedState_;

  /** Atomically tracks the state as indicated by the asynchronous
   * button events.   Bits not set in changedState_ must be zero. */
  uint8_t currentState_;

  task void signalState_task ()
  {
    uint8_t changed_state;
    uint8_t old_state;
    uint8_t new_state;
    uint8_t button_id = 0;

    atomic {
      /* Cache the values based on which we'll do the notification,
       * then update the last state to reflect the latest value. */
      changed_state = changedState_;
      old_state = lastState_;
      lastState_ = (lastState_ & (~ changedState_)) | currentState_;
      new_state = lastState_;
      currentState_ = changedState_ = 0;
    }
    /* Generate events for all buttons that changed state */
    while (changed_state) {
      uint8_t bit = (1 << button_id);
      bool was_pressed = !!(bit & old_state);
      if (bit & changed_state) {
        bool is_pressed = !!(bit & new_state);
        if (was_pressed == is_pressed) {
          signal Notify.notify[button_id](was_pressed ? BUTTON_RELEASED : BUTTON_PRESSED);
        }
        signal Notify.notify[button_id](is_pressed ? BUTTON_PRESSED : BUTTON_RELEASED);
        changed_state ^= bit;
      }
      ++button_id;
    }
  }

  command button_state_t Get.get[uint8_t button_id] ()
  {
    /* Consult our state cache rather than the current state so this
     * is consistent with delivered notifications. */
    atomic return (lastState_ & (1 << button_id)) ? BUTTON_PRESSED : BUTTON_RELEASED;
  }

  command error_t Notify.enable[uint8_t button_id] ()
  {
    atomic {
      /* NB: The ButtonP component will call back into this one to
       * initialize the button's state.  This allows the state to be
       * correct even if the button was enabled through another
       * interface. */
      signal ButtonBridge.setEnabled[button_id](TRUE);
    }
    return SUCCESS;
  }

  command error_t Notify.disable[uint8_t button_id] ()
  {
    atomic {
      signal ButtonBridge.setEnabled[button_id](FALSE);
    }
    return SUCCESS;
  }

  default event void Notify.notify[uint8_t button_id] (button_state_t val) { }

  async command bool ButtonBridge.initializeState[uint8_t button_id] (bool pressed)
  {
    uint8_t bit = (1 << button_id);
    atomic {
      if (pressed) {
        lastState_ |= bit;
      } else {
        lastState_ &= ~bit;
      }
    }
    return pressed;
  }

  async command void ButtonBridge.stateChange[uint8_t button_id] (bool pressed)
  {
    uint8_t bit = (1 << button_id);
    atomic {
      changedState_ |= bit;
      if (pressed) {
        currentState_ |= bit;
      } else {
        currentState_ &= ~bit;
      }
      post signalState_task();
    }
  }

  default async event void ButtonBridge.setEnabled[uint8_t button_id] (bool enabledp) { }
}
