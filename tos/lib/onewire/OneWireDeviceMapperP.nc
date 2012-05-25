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

/*
 * Implementation of standard Onewire device discovery process.
 * Adapted from Maxim AN-187: 1-Wire Search Algorithm
 * http://pdfserv.maxim-ic.com/en/an/AN187.pdf
 *
 * @author Doug Carlson <carlson@cs.jhu.edu>
 * @modified 6/16/10 initial revision
 */

module OneWireDeviceMapperP {
  uses {
    interface Resource;
    interface OneWireCrc;
    interface OneWireMaster;
  }
  provides {
    interface OneWireDeviceMapper;
  }
} implementation {
  uint8_t numDevices;
  onewire_t devices[MAX_ONEWIRE_DEVICES];
  bool devChanged;

  enum {
    S_IDLE = 0x0,
    S_BUSY = 0x1,
  };

  uint8_t state = S_IDLE;

  command uint8_t OneWireDeviceMapper.numDevices() {
    return numDevices;
  }

  command onewire_t OneWireDeviceMapper.getDevice(uint8_t index) {
    return devices[index];
  }

  command error_t OneWireDeviceMapper.refresh() {
    error_t err;
    if (state == S_IDLE) {
      err = call Resource.request();
      if (err == SUCCESS) {
        state = S_BUSY;
        return SUCCESS;
      }
      else {
        state = S_IDLE;
        return err;
      }
    } else {
      return EALREADY;
    }
  }

  // method declarations
  bool OWFirst();
  bool OWNext();
  bool OWSearch();

  // global search state
  onewire_t rom;

  int LastDiscrepancy;
  int LastFamilyDiscrepancy;
  int LastDeviceFlag;

  //--------------------------------------------------------------------------
  // Find the 'first' devices on the 1-Wire bus
  // Return TRUE  : device found, ROM number in rom buffer
  //        FALSE : no device present
  //
  bool OWFirst() {
     // reset the search state
     LastDiscrepancy = 0;
     LastDeviceFlag = FALSE;
     LastFamilyDiscrepancy = 0;
     return OWSearch();
  }

  //--------------------------------------------------------------------------
  // Find the 'next' devices on the 1-Wire bus
  // Return TRUE  : device found, ROM number in rom buffer
  //        FALSE : device not found, end of search
  //
  bool OWNext() {
     // leave the search state alone
     return OWSearch();
  }

  //--------------------------------------------------------------------------
  // Perform the 1-Wire Search Algorithm on the 1-Wire bus using the existing
  // search state.
  // Return TRUE  : device found, ROM number in rom buffer
  //        FALSE : device not found, end of search
  //
  // NOTE this was cut-n-pasted from the application note specified above.
  // the only changes made have been to make it comply with TEP 3 and to directly call OneWireMaster and OneWireCrc.
  bool OWSearch() {
     uint8_t id_bit_number;
     uint8_t last_zero, rom_byte_number, search_result;
     uint8_t id_bit, cmp_id_bit;
     uint8_t rom_byte_mask, search_direction;

     // initialize for search
     id_bit_number = 1;
     last_zero = 0;
     rom_byte_number = 0;
     rom_byte_mask = 1;
     search_result = 0;

     // if the last call was not the last one
     if (!LastDeviceFlag) {
        // 1-Wire reset
        if ( call OneWireMaster.reset() != SUCCESS) {
           // reset the search
           LastDiscrepancy = 0;
           LastDeviceFlag = FALSE;
           LastFamilyDiscrepancy = 0;
           return FALSE;
        }

        // issue the search command 
        call OneWireMaster.writeByte(0xF0);  

        // loop to do the search
        do {
           // read a bit and its complement
           id_bit = call OneWireMaster.readBit();
           cmp_id_bit = call OneWireMaster.readBit();

           // check for no devices on 1-wire
           if ( (id_bit == 1) && (cmp_id_bit == 1) ) {
              break;
           } 
           else {
              // all devices coupled have 0 or 1
              if (id_bit != cmp_id_bit) {
                 search_direction = id_bit;  // bit write value for search
              } 
              else {
                 // if this discrepancy if before the Last Discrepancy
                 // on a previous next then pick the same as last time
                 if (id_bit_number < LastDiscrepancy){
                    search_direction = ((rom.data[rom_byte_number] & rom_byte_mask) > 0);
                 } 
                 else {
                    // if equal to last pick 1, if not then pick 0
                    search_direction = (id_bit_number == LastDiscrepancy);
                 }

                 // if 0 was picked then record its position in LastZero
                 if (search_direction == 0) {
                    last_zero = id_bit_number;

                    // check for Last discrepancy in family
                    if (last_zero < 9) {
                       LastFamilyDiscrepancy = last_zero;
                    }
                 }
              }

              // set or clear the bit in the ROM byte rom_byte_number
              // with mask rom_byte_mask
              if (search_direction == 1) {
                rom.data[rom_byte_number] |= rom_byte_mask;
              } else {
                rom.data[rom_byte_number] &= ~rom_byte_mask;
              }

              // serial number search direction write bit
              call OneWireMaster.writeBit(search_direction);

              // increment the byte counter id_bit_number
              // and shift the mask rom_byte_mask
              id_bit_number++;
              rom_byte_mask <<= 1;

              // if the mask is 0 then go to new SerialNum byte rom_byte_number and reset mask
              if (rom_byte_mask == 0) {
                  rom_byte_number++;
                  rom_byte_mask = 1;
              }
           }
        } while(rom_byte_number < 8);  // loop until through all ROM bytes 0-7

        // if the search was successful then
        if (!((id_bit_number < 65) || !(call OneWireCrc.isValid(&rom)))) {
           // search successful so set LastDiscrepancy,LastDeviceFlag,search_result
           LastDiscrepancy = last_zero;
           // check for last device
           if (LastDiscrepancy == 0) {
              LastDeviceFlag = TRUE;
           }
           search_result = TRUE;
        }
     }

     // if no device found then reset counters so next 'search' will be like a first
     if (!search_result || !rom.data[0]) {
        LastDiscrepancy = 0;
        LastDeviceFlag = FALSE;
        LastFamilyDiscrepancy = 0;
        search_result = FALSE;
     }
     return search_result;
  }
  //-------------------
  // end of copied code

  task void doFirstTask();
  task void doNextTask();

  //if a device was found, continue searching. if not, release the bus and signal completion.  
  void checkAndContinue(bool devFound) {
    uint8_t i;

    if (devFound) {
      if(devices[numDevices].id != rom.id) {
        devChanged = TRUE;
      }
      devices[numDevices++] = rom;
      post doNextTask();
    }
    else {
      call OneWireMaster.reset();
      call Resource.release();
      for(i = numDevices; i < MAX_ONEWIRE_DEVICES; i++) {
        devices[i].id = ONEWIRE_NULL_ADDR;
      }
      state = S_IDLE;
      signal OneWireDeviceMapper.refreshDone(SUCCESS, devChanged);
    }
  }

  task void doFirstTask() {
    bool devFound = FALSE;
    devChanged = FALSE;
    numDevices = 0;

    atomic {
      devFound = OWFirst();
      checkAndContinue(devFound);
    }
  }

  task void doNextTask() {
    bool devFound = FALSE;

    atomic {
      devFound = OWNext();
      checkAndContinue(devFound);
    }
  }

  //begin search
  event void Resource.granted() {
    post doFirstTask();
  }
}
