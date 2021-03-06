/* DO NOT MODIFY
 * This file cloned from Msp430UsciUartA0C.nc for A3 */
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

#include "msp430usci.h"

/**
 * Generic configuration for a client that shares USCI_A3 in UART mode.
 */
generic configuration Msp430UsciUartA3C() {
  provides {
    interface Resource;
    interface UartStream;
    interface UartByte;
    interface Msp430UsciError;
  }
}
implementation {
  enum {
    CLIENT_ID = unique(MSP430_USCI_A3_RESOURCE),
  };

  components Msp430UsciA3P as UsciC;
  Resource = UsciC.Resource[CLIENT_ID];

  components Msp430UsciUartA3P as UartC;
  UartStream = UartC.UartStream[CLIENT_ID];
  UartByte = UartC.UartByte[CLIENT_ID];
  Msp430UsciError = UartC.Msp430UsciError[CLIENT_ID];

  UsciC.ResourceConfigure[CLIENT_ID] -> UartC.ResourceConfigure[CLIENT_ID];
}
