/*
 * Copyright (c) 2011 Eric B. Decker
 * Copyright (c) 2009-2010 People Power Co.
 * Copyright (c) 2000-2005 The Regents of the University of California.  
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

/**
 * @author Joe Polastre 
 * @author Cory Sharp
 * @author David Moss
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include "hardware.h"

configuration PlatformC { 
  provides interface Init as PlatformInit;
  uses     interface Init as PeripheralInit;
}

implementation {

  components PlatformP;
  PlatformInit = PlatformP;
  PeripheralInit = PlatformP.PeripheralInit;

  /* The following components require no initialization:
   * Button, Rf1a, RealTimeClock
   *
   * The following components require wiring initialization, but no code initialization:
   *     Usci
   */

  components PlatformPinsC;
  PlatformP.PlatformPins -> PlatformPinsC;

  components PlatformLedC;
  PlatformP.PlatformLed -> PlatformLedC;

  components PlatformUsciMapC;
  // No code initialization required; just connect the pins

  components Msp430PmmC;
  PlatformP.Pmm -> Msp430PmmC;

  components PlatformClockC;
  PlatformP.PlatformClock -> PlatformClockC;

  components PlatformOneWireInitC;
  PlatformP.OneWire -> PlatformOneWireInitC;

#if PLATFORM_HAS_FLASH
  components PlatformFlashInitC;
  PlatformP.PlatformFlash -> PlatformFlashInitC;
#endif  // PLATFORM_HAS_FLASH
}
