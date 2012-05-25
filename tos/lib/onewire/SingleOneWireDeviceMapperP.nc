/*
 * Copyright (c) 2010 Johns Hopkins University.
 * Copyright (c) 2010 People Power Co.
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

/*
 * Implementation of Onewire device discovery process for the case where
 * at most one device is ever connected to the bus. If more than one device
 * is present, the behavior of this component is undefined. In this situation,
 * it will most likely indicate that no devices are present (unless it so
 * happens that the bitwise AND of all the device IDs on the bus turns out
 * to have a valid CRC byte...).
 *
 * Adapted from Ds1825OneWireImplementationP by David Moss / People Power.
 *
 * @author David Moss
 * @author Doug Carlson <carlson@cs.jhu.edu>
 * @modified 6/16/10 first revision, from Ds1825OneWireImplementationP
 */ 

module SingleOneWireDeviceMapperP {
  uses {
    interface OneWireMaster;
    interface OneWireCrc;
    interface Resource;
  }
  provides {
    interface OneWireDeviceMapper;
  }
} 
implementation {
  uint8_t numDevices;
  onewire_t device;
  error_t refreshResult;
  bool devChanged;

  enum{
    CMD_GET_ID=0x33,
  };

 command uint8_t OneWireDeviceMapper.numDevices() {
    return numDevices;
  }

  command onewire_t OneWireDeviceMapper.getDevice(uint8_t index) {
    return device;
  }

  command error_t OneWireDeviceMapper.refresh() {
    return call Resource.request();
  }

  task void signalDoneTask() {
    call Resource.release();
    signal OneWireDeviceMapper.refreshDone(refreshResult, devChanged);
  }  

  event void Resource.granted() {
    int max_checks = 10;
    uint8_t i;
    bool valid_rom = FALSE;
    onewire_t rom;
    refreshResult = SUCCESS;

    while ((0 < max_checks--) && (! valid_rom)) {
      call OneWireMaster.init();

      if(call OneWireMaster.reset() != SUCCESS) {
        call OneWireMaster.release();
        refreshResult = FAIL;
        return;
      }

      call OneWireMaster.writeByte(CMD_GET_ID);

      for(i = 0; i < ONEWIRE_DATA_LENGTH; i++) {
        rom.data[i] = call OneWireMaster.readByte();
      }

      call OneWireMaster.release();
      valid_rom = call OneWireCrc.isValid(&rom);
    }
    refreshResult = (valid_rom) ? SUCCESS : FAIL;
    if (rom.id != device.id) {
      devChanged = TRUE;
    }
    if (valid_rom) {
      device = rom;
      numDevices = 1;
    }
    else {
      device.id = ONEWIRE_NULL_ADDR;
      numDevices = 0;
    }
    post signalDoneTask();
  }
}
