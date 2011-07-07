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

module DisplayCodeP {
  provides {
    interface Init;
    interface StdControl;
    interface DisplayCode[ uint8_t code ];
  }
#if ! NDEBUG
  uses {
    interface Led as Marker;
    interface MultiLed;
    interface Alarm<T32khz, uint32_t> as Alarm32khz;
  }
#endif /* NDEBUG */
} implementation {

#if NDEBUG
  /* Inhibit the DisplayCode functionality. */
  command error_t StdControl.start () { return SUCCESS; }
  command error_t StdControl.stop () { return SUCCESS; }
  async command uint8_t DisplayCode.id[ uint8_t code ] () { return code; }
  async command void DisplayCode.enable[ uint8_t code ] (bool is_enabled) { }
  async command void DisplayCode.showLimited[ uint8_t code ] (unsigned int limit_count) { }
  async command void DisplayCode.setValueWidth[ uint8_t code ] (unsigned int value_width_nyb) { }
  async command void DisplayCode.setValue[ uint8_t code ] (displayCodeValue_t value) { }
  async command displayCodeValue_t DisplayCode.getValue[ uint8_t code ] () { return 0; }
  async command void DisplayCode.lock[ uint8_t code ] () { }
#else /* NDEBUG */
  enum {
    /** System is off: LEDs are controlled by other components. */
    DS_disabled,
    /** No codes are enabled for display. */
    DS_dormant,
    /** Start a new cycle through all codes */
    DS_startDisplay,
    /** Begin the display cycle for the next code.  This will
     * increment the index until an enabled code is found.  If all
     * codes are checked without finding an enabled code, the display
     * goes to DS_dormant. */
    DS_nextCode,
    /** Begin displaying the current code */
    DS_startCodeDisplay,
    /** Light only the marker LED, indicating a code value */
    DS_displayCodeMarker,
    /** Light the LEDs associated with the current code value */
    DS_displayCodeValue,
    /** Display the next nybble from the value associated with the
     * current code. */
    DS_displayValue,
    DS_INVALID,
  };

  /** State of the display subsystem. */
  uint8_t displayState__;

  enum {
    /** No code is locked.  Display cycles through all active codes. */
    LM_unlocked,
    /** The display is locked to a specific code, and is spinning
     * waiting for the timeout that moves it to the next state. */
    LM_spinning,
    /** The display is locked to a specific code and is ready to
     * proceed to the next stage of its display. */
    LM_ready,
  };
  /** Code lock mode */
  volatile uint8_t lockMode__;

  enum {
    /** Mask off the bits that will be displayed via MultiLed */
    LED_NybbleMask = 0x0F,
    /** Number of bits that fit within the MultiLed display when displaying a nybble */
    LED_NybbleSize_bits = 4,
    /** Number of 32 KHz ticks for each marker and code display phase
     * within a cycle. */
    Timeout_CodeRate_32k = (32768U / (2 * DISPLAY_CODE_CODE_RATE_HZ)),
    /* The number of marker+code display phases within a display
     * cycle */
    CodeRateRepetitions = (DISPLAY_CODE_CODE_DURATION_SEC * DISPLAY_CODE_CODE_RATE_HZ),
    /** The maximum value for a showLimited parameter */
    MaxLimitCount = 15,
  };

  /** Values associated with each code */
  displayCodeValue_t codeValue__[DISPLAY_CODE_MAX_CODES];
  typedef struct codeState_t {
    /** Non-zero iff the code should appear in the display cycle */
    uint8_t enabled: 1;
    /** Number of nybbles from codeValue__ that should be displayed for the code */
    uint8_t value_width_nyb: 3;
    /** Number of repetitions remaining for a limited display */
    uint8_t limit_count: 4;
  } codeState_t;
  /** State of each code */
  codeState_t codeState__[DISPLAY_CODE_MAX_CODES];
  /** Number of codes supported by the module */
  const uint8_t NumCodes = sizeof(codeState__) / sizeof(*codeState__);

  /** The number of codes displayed in this grand cycle (iteration
   * over all code values).  If a grand cycle completes without
   * incrementing this, the display goes dormant. */
  uint8_t displayCount_;
  /** The index of the code currently being displayed */
  uint8_t codeIndex__;
  /** The marker/code phase repetition within a display cycle */
  uint8_t codeRep_;
  /** The nybble index used to extract the current value display */
  int8_t nybbleNumber_;

  /** Execute the next step in the display.
   *
   * @note This should only be invoked when transitioning out of
   * DS_dormant or when the alarm indicates the time for the next
   * stage has arrived.  Asynchronously entering this can result in
   * displays that confuse the user. */
  void executeDisplayState ()
  {
    uint32_t wakeup_32k = 0;

    atomic {
      uint8_t exit_state = DS_INVALID;

      if (DS_disabled == displayState__) {
        return;
      }
      while (DS_INVALID == exit_state) {
        uint8_t next_state = DS_INVALID;
        codeState_t* csp;

        switch (displayState__) {
          default:
          case DS_dormant:
            /* Assume nothing's going on.  If something other than
             * code 0 is enabled, we'll enter the normal cycle. */
            exit_state = DS_dormant;
            for (codeIndex__ = 1; codeIndex__ < NumCodes; ++codeIndex__) {
              if (codeState__[codeIndex__].enabled) {
                exit_state = DS_INVALID;
                break;
              }
            }
            if (DS_dormant == exit_state) {
              csp = codeState__;
              if (csp->enabled) {
                call MultiLed.set(codeValue__[0]);
              }
              break;
            }
            //FALLTHRU
          case DS_startDisplay:
            if (LM_unlocked == lockMode__) {
              displayCount_ = 1;
              codeIndex__ = NumCodes - 1;
            }
            //FALLTHRU
          case DS_nextCode:
            if (LM_unlocked != lockMode__) {
              next_state = DS_startCodeDisplay;
              break;
            }
            while (1) {
              if (NumCodes == ++codeIndex__) {
                codeIndex__ = 0;
                if (0 == displayCount_) {
                  next_state = DS_dormant;
                  break;
                }
                displayCount_ = 0;
              }
              csp = codeState__ + codeIndex__;
              if (csp->enabled) {
                if (0 != codeIndex__) {
                  ++displayCount_;
                }
                if (0 < csp->limit_count) {
                  if (0 == --csp->limit_count) {
                    csp->enabled = FALSE;
                  }
                }
                next_state = DS_startCodeDisplay;
                break;
              }
            }
            break;
          case DS_startCodeDisplay:
            codeRep_ = 0;
            //FALLTHRU
          case DS_displayCodeMarker:
            call MultiLed.set(call MultiLed.get() & (~ LED_NybbleMask));
            call Marker.on();
            wakeup_32k = Timeout_CodeRate_32k;
            exit_state = DS_displayCodeValue;
            break;
          case DS_displayCodeValue:
            csp = codeState__ + codeIndex__;
            call MultiLed.set(codeIndex__ & LED_NybbleMask);
            call Marker.off();
            wakeup_32k = Timeout_CodeRate_32k;
            if (++codeRep_ < CodeRateRepetitions) {
              exit_state = DS_displayCodeMarker;
            } else if (0 == csp->value_width_nyb) {
              exit_state = DS_nextCode;
            } else {
              exit_state = DS_displayValue;
              nybbleNumber_ = csp->value_width_nyb;
            }
            break;
          case DS_displayValue: {
            uint8_t display_value = (codeValue__[codeIndex__] >> (--nybbleNumber_ * LED_NybbleSize_bits));
            call MultiLed.set(LED_NybbleMask & display_value);
            call Marker.set(nybbleNumber_ & 0x01);
            wakeup_32k = 32768UL * DISPLAY_CODE_VALUE_DURATION_SEC;
            exit_state = (0 == nybbleNumber_) ? DS_nextCode : DS_displayValue;
            break;
          }
        }
        displayState__ = next_state;
      }
      displayState__ = exit_state;
    } // atomic
    if (wakeup_32k) {
      call Alarm32khz.start(wakeup_32k);
    }
  }

  task void displayState_task () { executeDisplayState(); }

  async event void Alarm32khz.fired ()
  {
    if (LM_unlocked == lockMode__) {
      post displayState_task();
    } else {
      lockMode__ = LM_ready;
    }
  }

  async command uint8_t DisplayCode.id[ uint8_t code ] () { return code; }
  
  void enable__ (uint8_t code,
                 bool is_enabled)
  {
    codeState__[code].enabled = is_enabled;
    if (is_enabled && (DS_dormant == displayState__)) {
      post displayState_task();
    }
  }

  async command void DisplayCode.enable[ uint8_t code ] (bool is_enabled)
  {
    if (code >= NumCodes) {
      return;
    }
    atomic {
      enable__(code, is_enabled);
    }
  }

  async command void DisplayCode.showLimited[ uint8_t code ] (unsigned int limit_count)
  {
    bool is_enabled;
    if (code >= NumCodes) {
      return;
    }
    if (limit_count > MaxLimitCount) {
      limit_count = MaxLimitCount;
    }
    atomic {
      if (0 == limit_count) {
        is_enabled = FALSE;
      } else {
        is_enabled = TRUE;
        codeState__[code].limit_count = limit_count;
      }
      enable__(code, is_enabled);
    }
  }

  async command void DisplayCode.setValueWidth[ uint8_t code ] (unsigned int value_width_nyb)
  {
    if (code >= NumCodes) {
      return;
    }
    atomic {
      codeState__[code].value_width_nyb = value_width_nyb;
    }
  }

  async command void DisplayCode.setValue[ uint8_t code ] (displayCodeValue_t value)
  {
    if (code >= NumCodes) {
      return;
    }
    atomic {
      codeValue__[code] = value;
      if ((0 == code) && (DS_dormant == displayState__)) {
        post displayState_task();
      }
    }
  }

  async command displayCodeValue_t DisplayCode.getValue[ uint8_t code ] ()
  {
    atomic return codeValue__[code];
  }

  async command void DisplayCode.lock[ uint8_t code ] ()
  {
    if (code >= NumCodes) {
      return;
    }
    atomic {
      codeIndex__ = code;
      displayState__ = DS_startDisplay;
      lockMode__ = LM_spinning;
      codeState__[code].enabled = TRUE;
    }
    while (1) {
      bool spinning = TRUE;
      executeDisplayState();
      while (spinning) {
        atomic {
          spinning = ! (LM_ready == lockMode__);
          lockMode__ = LM_spinning;
        }
      }
    }
  }

  command error_t StdControl.start ()
  {
    atomic {
      if (DS_disabled == displayState__) {
        displayState__ = DS_dormant;
        post displayState_task();
      }
    }
    return SUCCESS;
  }

  command error_t StdControl.stop ()
  {
    atomic {
      if (DS_disabled != displayState__) {
        displayState__ = DS_disabled;
        call Alarm32khz.stop();
      }
    }
    return SUCCESS;
  }

  command error_t Init.init ()
  {
    return call StdControl.start();
  }
      
#endif /* NDEBUG */
}
