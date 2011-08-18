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
 * De-facto standard component for platform independent access to a serial port.
 *
 * This implementation supports the TI EM430 and other MSP430XV2-based boards.
 *
 * Note that, since the standard practice is to use StdControl to
 * start and stop this module (which requests and releases the
 * corresponding USCI UART module), inclusion of this into an
 * application is incompatible with sharing the UART among multiple
 * clients in the TEP108 sense of resource sharing.
 *
 * @author David Moss
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

configuration PlatformSerialC {
  provides {
    interface StdControl;
    interface UartStream;
    interface UartByte;
    interface Msp430UsciError;
  }
}

implementation {

  components PlatformSerialP;
  StdControl = PlatformSerialP;

  components new Msp430UsciUartA0C() as UartC;

  UartStream = UartC;
  UartByte = UartC;
  Msp430UsciError = UartC;
  PlatformSerialP.Resource -> UartC.Resource;

}
