/*
 * Copyright (c) 2009-2010 People Power Co.
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
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

#include "hardware.h"

configuration PlatformLedsC {
  provides {
    interface Init;
    interface Leds;
  }
}
implementation {
  components PlatformLedsP;
  Leds = PlatformLedsP;
  Init = PlatformLedsP;

  components HplMsp430GeneralIOC as GeneralIOC;

  /* RED LED (D1) at P4.7 */
  components new Msp430GpioC() as Led0Impl;
  Led0Impl -> GeneralIOC.Port47;
  PlatformLedsP.Led0 -> Led0Impl;

  /* Yellow LED (D2) at P4.6 */
  components new Msp430GpioC() as Led1Impl;
  Led1Impl -> GeneralIOC.Port46;
  PlatformLedsP.Led1 -> Led1Impl;

 /* Green LED (D1) at P4.5 */
  components new Msp430GpioC() as Led2Impl;
  Led2Impl -> GeneralIOC.Port45;
  PlatformLedsP.Led2 -> Led2Impl;
}
