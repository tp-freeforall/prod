/* 
 * Copyright (c) 2009-2010 People Power Company
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

/**
 * @author David Moss
 */

#include "UserButton.h"
#include "PlatformButtons.h"

configuration PlatformButtonsC {
  provides {
    interface Get<button_state_t>[uint8_t button_id];
    interface Notify<button_state_t>[uint8_t button_id];
    interface Button as Button0;
    interface Button as Button1;
#if 2 < PLATFORM_BUTTON_COUNT
    interface Button as Button2;
#if 3 < PLATFORM_BUTTON_COUNT
    interface Button as Button3;
#endif // 3 < PLATFORM_BUTTON_COUNT
#endif // 2 < PLATFORM_BUTTON_COUNT
  }
} implementation {

  components HplMsp430GeneralIOC as GeneralIoC;
  components HplMsp430InterruptC as InterruptC;

  /*
   * Define as many Buttons's as your platform has available
   */

  enum {
    BUTTON_0 = 0,
    BUTTON_1 = 1,
#if 2 < PLATFORM_BUTTON_COUNT
    BUTTON_2 = 2,
#if 3 < PLATFORM_BUTTON_COUNT
    BUTTON_3 = 3,
#endif // 3 < PLATFORM_BUTTON_COUNT
#endif // 2 < PLATFORM_BUTTON_COUNT
  };

  components ButtonBridgeP;
  Get = ButtonBridgeP.Get;
  Notify = ButtonBridgeP.Notify;

  components new ButtonP(FALSE, 0) as Button0C;
  components new Msp430InterruptC() as Button0InterruptC;
  Button0C.ButtonInterrupt -> Button0InterruptC;
  ButtonBridgeP.ButtonBridge[0] <- Button0C;
  Button0 = Button0C;

  components new ButtonP(FALSE, 1) as Button1C;
  components new Msp430InterruptC() as Button1InterruptC;
  Button1C.ButtonInterrupt -> Button1InterruptC;
  ButtonBridgeP.ButtonBridge[1] <- Button1C;
  Button1 = Button1C;

#if 2 < PLATFORM_BUTTON_COUNT
  components new ButtonP(FALSE, 2) as Button2C;
  components new Msp430InterruptC() as Button2InterruptC;
  Button2C.ButtonInterrupt -> Button2InterruptC;
  ButtonBridgeP.ButtonBridge[2] <- Button2C;
  Button2 = Button2C;

#if 3 < PLATFORM_BUTTON_COUNT
  components new ButtonP(FALSE, 3) as Button3C;
  components new Msp430InterruptC() as Button3InterruptC;
  Button3C.ButtonInterrupt -> Button3InterruptC;
  ButtonBridgeP.ButtonBridge[3] <- Button3C;
  Button3 = Button3C;
#endif // 3 < PLATFORM_BUTTON_COUNT
#endif // 2 < PLATFORM_BUTTON_COUNT

#if defined(SURF_REV_A)
  Button0InterruptC.HplInterrupt -> InterruptC.Port20;
  Button0C.ButtonPin -> GeneralIoC.Port20;
  Button1InterruptC.HplInterrupt -> InterruptC.Port21;
  Button1C.ButtonPin -> GeneralIoC.Port21;
#else // all other SuRF models
  Button0InterruptC.HplInterrupt -> InterruptC.Port10;
  Button0C.ButtonPin -> GeneralIoC.Port10;
  Button1InterruptC.HplInterrupt -> InterruptC.Port11;
  Button1C.ButtonPin -> GeneralIoC.Port11;
#if 2 < PLATFORM_BUTTON_COUNT
  Button2InterruptC.HplInterrupt -> InterruptC.Port26;
  Button2C.ButtonPin -> GeneralIoC.Port26;
#if 3 < PLATFORM_BUTTON_COUNT
  Button3InterruptC.HplInterrupt -> InterruptC.Port27;
  Button3C.ButtonPin -> GeneralIoC.Port27;
#endif // 3 < PLATFORM_BUTTON_COUNT
#endif // 2 < PLATFORM_BUTTON_COUNT
#endif // SURF_REV_x

}
