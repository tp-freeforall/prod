/*
 * Copyright (c) 2010 Johns Hopkins University.
 * Copyright (c) 2007, Vanderbilt University
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
 *
 * @author Janos Sallai
 * @author David Moss
 * @author Doug Carlson
 * @modified 6/16/10 added definitions for general multi-type multi-device onewire bus.
 */

#ifndef ONEWIRE_H
#define ONEWIRE_H

#ifndef MAX_ONEWIRE_DEVICES_PER_TYPE
#define MAX_ONEWIRE_DEVICES_PER_TYPE 8
#endif

#ifndef MAX_ONEWIRE_DEVICES
#define MAX_ONEWIRE_DEVICES 16
#endif

enum {
  ONEWIRE_SERIAL_LENGTH = 6,
  ONEWIRE_DATA_LENGTH = 8,
  ONEWIRE_WORDS_LENGTH = 2,
};

typedef union onewire_t {
  uint8_t data[ONEWIRE_DATA_LENGTH];

  struct {
     uint8_t familyCode;
     uint8_t serial[ONEWIRE_SERIAL_LENGTH];
     uint8_t crc;
  };
  uint32_t words[ONEWIRE_WORDS_LENGTH];
  uint64_t id;
} onewire_t;

#define ONEWIRE_NULL_ADDR 0LL
#define ONEWIRE_CLIENT "OneWire Client"
#endif // ONEWIRE_H
