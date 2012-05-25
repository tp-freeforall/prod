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

#include "OneWire.h"

/**
 * POLYNOMIAL = x^8 + x^5 + x^4 + 1
 * @author Cory Sharp
 * @author David Moss
 */

module OneWireCrcP {
  provides {
    interface OneWireCrc;
  }
}

implementation {

  /***************** Functions ****************/
  uint8_t crc8( uint8_t crc, uint8_t newByte ) {
    int i;
    crc ^= newByte;

    for(i = 0; i < 8; i++) {
      if( crc & 1 ) {
        crc = (crc >> 1) ^ 0x8c;
      } else {
        crc >>= 1;
      }
    }
    return crc;
  }


  /***************** OneWireCrc Commands ****************/
  async command uint8_t OneWireCrc.crc(onewire_t *rom) {
    int i;
    uint8_t crc = 0;

    for(i = 0; i < 7; i++) {
      crc = crc8(crc, rom->data[i]);
    }
    return crc;
  }


  async command bool OneWireCrc.isValid(onewire_t *rom) {
    return (rom->crc == call OneWireCrc.crc(rom)) && (rom->crc != 0);
  }
}
