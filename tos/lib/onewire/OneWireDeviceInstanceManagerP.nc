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
 * Implementation of basic onewire device-type specific device instance
 * manager.  Up to maxDevices can be supported at once. If more are attached
 * to the bus, they will not be addressable.
 * 
 * @author Doug Carlson <carlson@cs.jhu.edu>
 * @modified 6/16/10
 */

generic module OneWireDeviceInstanceManagerP(uint8_t maxDevices) {
  provides {
    interface OneWireDeviceInstanceManager;
  }
  uses {
    interface OneWireDeviceType;
    interface OneWireDeviceMapper;
  }
} 
implementation {
  uint8_t numDevices;
  onewire_t devices[maxDevices];
  onewire_t curDevice; 

  command uint8_t OneWireDeviceInstanceManager.numDevices() {
    return numDevices;
  }

  command onewire_t OneWireDeviceInstanceManager.getDevice(uint8_t index) {
    return devices[index];
  }

  command error_t OneWireDeviceInstanceManager.setDevice(onewire_t id) {
    curDevice = id;
    return SUCCESS;
  }

  command onewire_t OneWireDeviceInstanceManager.currentDevice() {
    return curDevice;
  }

  command error_t OneWireDeviceInstanceManager.refresh() {
    return call OneWireDeviceMapper.refresh();
  }

  task void checkDevicesTask() {
    int k;
    onewire_t cur;
    bool devicesChanged = FALSE;
    uint8_t lastNumDevices = numDevices;

    numDevices = 0;

    for (k=0; k < call OneWireDeviceMapper.numDevices() && numDevices < MAX_ONEWIRE_DEVICES_PER_TYPE; k++) {
      cur = call OneWireDeviceMapper.getDevice(k);
      //printf("Checking %llx: %x\n\r", cur.id, call OneWireDeviceType.isOfType(cur));
      if (call OneWireDeviceType.isOfType(cur)) {
        if (devices[numDevices].id != cur.id) {
          devicesChanged = TRUE;
        }
        devices[numDevices++] = cur;
      }
    }
    devicesChanged = devicesChanged || (numDevices != lastNumDevices);

    signal OneWireDeviceInstanceManager.refreshDone(SUCCESS, devicesChanged);
  } 

  event void OneWireDeviceMapper.refreshDone(error_t result, bool devicesChanged) {
    if (devicesChanged && result == SUCCESS) {
      post checkDevicesTask();
    }
    else {
      signal OneWireDeviceInstanceManager.refreshDone(result, FALSE);
    }
  }
}
