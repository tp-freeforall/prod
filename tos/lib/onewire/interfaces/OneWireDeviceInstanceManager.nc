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
 *
 *
 * Provides commands/events for identifying which onewire devices are
 * present for a specific device type.
 *
 * It is assumed that each device type in use will have a single
 * OneWireDeviceInstanceManager, and all of these will share a single general
 * OneWireDeviceMapper. This is the primary means of hiding device discovery
 * and type identification from the user application.  Additionally, the
 * OneWireDeviceInstanceManager maintains the state of which specific instance
 * for this type is intended for use.
 *
 * @author Doug Carlson <carlson@cs.jhu.edu>
 * @modified 6/16/10 initial revision
 */

interface OneWireDeviceInstanceManager {
  /**
   * Request the manager to refresh its list of attached devices.
   *
   * @return SUCCESS if the request will be accepted,
   *         EBUSY if a refresh is already pending.
   *
   *         If SUCCESS is returned, refreshDone will be signalled at
   *         some point in the future.
   */
  command error_t refresh();

  /**
   * Indicate completion of a device-list refresh. Note that this may be
   * signalled without an explicit call to the refresh command (i.e. if the
   * device mapper periodically checks the bus, if another user of the
   * deviceMapper calls refresh, etc).
   *
   * @param result SUCCESS if the refresh completed normally, otherwise FAIL.
   * @param devicesChanged TRUE if the list of attached devices FOR THIS
   *        MANAGER is different from the list of attached devices at the
   *        last time that refreshDone was signalled.
   */
  event void refreshDone(error_t result, bool devicesChanged);

  /**
   * Return the number of currently-present devices covered by this manager.
   *
   * @return the number of currently-present devices covered by this manager.
   */
  command uint8_t numDevices();

  /**
    * Get the hardware ID of a currently-present device.
    * @param index The index of the device to retrieve.
    * @return The hardware ID of the device at index. This will be equal to
    *         NULL_ONEWIRE_ADDR if an index outside of [0, numDevices()] is
    *         provided.
    */
  command onewire_t getDevice(uint8_t);

  /**
   * Set the "selected" device instance for this manager.
   *
   * Note that this updates the internal state of this manager, but does not
   * cause any activity on the bus or resource-locking.  For instance, the
   * user might set the thermometer to be read through this interface, but
   * the bus won't be locked and the device won't be addressed until the
   * user calls Read (on the public thermometer component).
   *
   * @param id The hardware ID of the device to be set.
   * @return SUCCESS always. Future implementations may want to validate
   *         that the ID indicated is of the correct type etc.
   */ 
  command error_t setDevice(onewire_t id);
  
  /**
   * Get the last hardware ID passed as parameter to setDevice.
   * @return Last hardware ID passed to setDevice. 
   */
  command onewire_t currentDevice();
}
