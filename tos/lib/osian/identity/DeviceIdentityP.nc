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

#include "odi.h"

/**
 * @author David Moss
 * @author Peter Bigot
 */
module DeviceIdentityP {
  provides {
    interface Init;
    interface DeviceIdentity;
  }
  uses {
    interface OneWire;
  }
} implementation {

/* Set default metadata values */
#ifndef OSIAN_DEVICE_OUI
#define OSIAN_DEVICE_OUI 0xB0C8AD
#endif /* OSIAN_DEVICE_OUI */
#ifndef OSIAN_DEVICE_SENSOR
#define OSIAN_DEVICE_SENSOR 0
#endif /* OSIAN_DEVICE_SENSOR */
#ifndef OSIAN_DEVICE_ACTUATOR
#define OSIAN_DEVICE_ACTUATOR 0
#endif /* OSIAN_DEVICE_ACTUATOR */
#ifndef OSIAN_DEVICE_CLASS
#define OSIAN_DEVICE_CLASS ODI_CLS_Unregistered
#endif /* OSIAN_DEVICE_CLASS */
#ifndef OSIAN_DEVICE_TYPE
#define OSIAN_DEVICE_TYPE 1
#endif /* OSIAN_DEVICE_TYPE */

  /** OSIAN Device Identifier, basically an EUI-64 with extra info.
   *
   * @note Don't bother trying to initialize this at compile-time.
   * nx_structs with bit fields don't translate into something that
   * can be statically initialized. */
  odi_t odi;

  command error_t Init.init ()
  {
    static bool done;
    error_t rc = SUCCESS;
    if (done) {
      return SUCCESS;
    }
    done = TRUE;
    odi.oui = OSIAN_DEVICE_OUI;
    odi.reserved = 0;
    odi.sensor = OSIAN_DEVICE_SENSOR;
    odi.actuator = OSIAN_DEVICE_ACTUATOR;
    odi.deviceClass = OSIAN_DEVICE_CLASS;
    odi.deviceType = OSIAN_DEVICE_TYPE;
    {
      onewire_t rom;
      uint32_t id = 0;

      rc = call OneWire.getId(&rom);
      if (SUCCESS == rc) {
        uint8_t* sp = rom.serial;
        id = (id << 8) | sp[3];
        id = (id << 8) | sp[2];
        id = (id << 8) | sp[1];
        id = (id << 8) | sp[0];
      }
      odi.id = id;
    }
    return rc;
  }

  command const odi_t* DeviceIdentity.get ()
  {
    call Init.init();
    return &odi;
  }

  command const ieee_eui64_t* DeviceIdentity.getEui64 () { return (const ieee_eui64_t*)call DeviceIdentity.get(); }

  command const char * DeviceIdentity.getDescription () { return 0; }

}
