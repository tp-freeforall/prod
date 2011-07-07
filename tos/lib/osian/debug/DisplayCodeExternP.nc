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

/** One module to define the extern functions that link to the
 * DisplayCode feature.
 *
 * If you use both DisplayCodeC and DummyDisplayCodeC in the same
 * application, you'll get a warning about fanout for the
 * DisplayCode.id() return value.  That's insignificant.  You'll also
 * not be able to dummy-out any calls through the extern functions.
 * Oh well.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
module DisplayCodeExternP {
  uses {
    interface DisplayCode[ uint8_t code ];
  }
} implementation {

  /* Globally visible access to functionality */
  void DisplayCode_enable (uint8_t code, bool is_enabled) @C() { call DisplayCode.enable[code](is_enabled); }
  void DisplayCode_showLimited (uint8_t code, unsigned int limit_count) @C() { call DisplayCode.showLimited[code](limit_count); }
  void DisplayCode_setValueWidth (uint8_t code, unsigned int value_width_nyb) @C() { call DisplayCode.setValueWidth[code](value_width_nyb); }
  void DisplayCode_setValue (uint8_t code, displayCodeValue_t value) @C() { call DisplayCode.setValue[code](value); }
  displayCodeValue_t DisplayCode_getValue (uint8_t code) @C() { return call DisplayCode.getValue[code](); }
  void DisplayCode_lock (uint8_t code) @C() { call DisplayCode.lock[code](); }

}
