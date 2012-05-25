/*
 * Copyright (c) 2010 Johns Hopkins University.
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
 * Basic device instance manager component, intended for use with a single
 * device-type.  This will be wired automatically if the driver uses the
 * OneWireBusClientC component.  maxDevices determines the maximum number
 * of onewire devices which can be managed by this component.  If this number
 * is exceeded, some devices may no longer be addressable.
 *
 * @author Doug Carlson <carlson@cs.jhu.edu>
 * @modified 6/16/10 first revision
 */

generic configuration OneWireDeviceInstanceManagerC(uint8_t maxDevices) {
  provides {
    interface OneWireDeviceInstanceManager;
  }
  uses {
    interface OneWireDeviceMapper;
    interface OneWireDeviceType;
  }
} 
implementation {
  components new OneWireDeviceInstanceManagerP(maxDevices);
  OneWireDeviceInstanceManager = OneWireDeviceInstanceManagerP;

  OneWireDeviceInstanceManagerP.OneWireDeviceMapper = OneWireDeviceMapper;
  OneWireDeviceInstanceManagerP.OneWireDeviceType = OneWireDeviceType;  
}
