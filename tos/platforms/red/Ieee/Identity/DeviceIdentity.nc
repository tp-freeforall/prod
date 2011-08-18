/*
 * Copyright (c) 2009-2010 People Power Company
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
 * - Neither the name of the People Power Company nor the names of
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

#include "IeeeEui64.h"
#include "odi.h"


/** Access the board OSIAN Device Identifier.
 *
 * The ODI is a tuple of values encoded in a sixty-four bit unsigned
 * integer structurally consistent with IEEE EUI64 values.
 *
 * A key feature of the ODI is that it is immutable.  In the standard
 * implementation DeviceIdentityC, the constant metadata fields like
 * device class and type can be defined at compile time through the
 * use of the ODI_DEFAULT_field preprocessor symbols (which can be
 * conveniently set using the odi_field make extras).  Alternative
 * implementations that obtain ODI data from the environment are
 * possible.
 *
 * Regardless of implementation, once an ODI value is returned, the
 * implementation must guarantee that the same value will be returned
 * on all subsequent calls.
 * 
 * @author Peter Bigot
 * @author David Moss
 */
interface DeviceIdentity {
 
  /** Get a pointer to the ODI structure.
   *
   * This function should not be invoked prior to MainC.Boot.booted(),
   * and must not be invoked from any function in the
   * DeviceIdentityConfiguration interface.
   *
   * Implementations must guarantee that multiple invocations of this
   * function always return a pointer to the same value. */
  command const odi_t * get ();

  /** Get a pointer to the ODI value, cast as an IEEE EUI64 value.
   *
   * This function is expected to invoke get().
   */
  command const ieee_eui64_t * getEui64 ();

  /** Get an optional human-readable description of the device.
   *
   * Unlike the ODI value itself, the description field may change
   * from an undefined value (a null pointer) to a defined value.  For
   * example, it may be provided by an external service that uses the
   * device ODI as a key.  It is, however, immutable after being
   * set. */
  command const char * getDescription ();
}

