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

#ifndef OSIAN_DISPLAY_CODE_H_
#define OSIAN_DISPLAY_CODE_H_

/** The type associated with context-specific values stored in debug
 * codes.  The display width can be reduced to zero through seven
 * nybbles of this value. */
typedef uint16_t displayCodeValue_t;

#ifndef DISPLAY_CODE_MAX_CODES
/** Maximum number of codes supported in the infrastructure.  The size
 * should not exceed the 2^N where N is the number of LEDs available
 * for code display. */
#define DISPLAY_CODE_MAX_CODES 16
#endif /* DISPLAY_CODE_MAX_CODES */

#ifndef DISPLAY_CODE_CODE_RATE_HZ
/** Blink rate for the display that identifies a debug code */
#define DISPLAY_CODE_CODE_RATE_HZ 4
#endif /* DISPLAY_CODE_CODE_RATE_HZ */

#ifndef DISPLAY_CODE_CODE_DURATION_SEC
/** Duration of the blinking code display */
#define DISPLAY_CODE_CODE_DURATION_SEC 2
#endif /* DISPLAY_CODE_DURATION_SEC */

#ifndef DISPLAY_CODE_VALUE_DURATION_SEC
/** Duration of display of each section of an associated code value. */
#define DISPLAY_CODE_VALUE_DURATION_SEC 2
#endif /* DISPLAY_CODE_VALUE_DURATION_SEC */

/* Provide access to DisplayCode capability bypassing the component
 * interface.  This is often used for pure debugging, and having to
 * modify the component wiring to get access to it from a new
 * component is too much hassle.
 *
 * These functions are defined in the DisplayCodeExternP module, which
 * should be referenced by at least one, probably all, configurations
 * that present the same interface as DisplayCodeC. */
extern void DisplayCode_enable (uint8_t code, bool is_enabled) @C();
extern void DisplayCode_showLimited (uint8_t code, unsigned int limit_count) @C();
extern void DisplayCode_setValueWidth (uint8_t code, unsigned int value_width_nyb) @C();
extern void DisplayCode_setValue (uint8_t code, displayCodeValue_t value) @C();
extern displayCodeValue_t DisplayCode_getValue (uint8_t code) @C();
extern void DisplayCode_lock (uint8_t code) @C();

#endif /* OSIAN_DISPLAY_CODE_H_ */
