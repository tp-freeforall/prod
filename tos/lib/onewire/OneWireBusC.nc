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
 * Exposes onewire communication primitives, resource for locking bus,
 * and device discovery.
 *
 * Components using this SHOULD observe the same usage rules specified
 * in BasicOneWireBusC.  This wires the device-mapper into the Resource
 * and OneWireMaster interfaces necessary for proper locking of the bus
 * when discovery and device-specific operations both occur.
 *
 * @author Doug Carlson <carlson@cs.jhu.edu>
 * @modified 6/16/10
 */

configuration OneWireBusC {
  provides {
    interface OneWireMaster;
    interface Resource[uint8_t clientId];
    interface OneWireDeviceMapper;
  }
} implementation {
  enum {
    MAPPER_CLIENT_ID = unique(ONEWIRE_CLIENT),
  };

  components OneWireDeviceMapperC,
    BasicOneWireBusC;

  OneWireMaster = BasicOneWireBusC.OneWireMaster;
  Resource = BasicOneWireBusC.Resource;

  OneWireDeviceMapper = OneWireDeviceMapperC;

  OneWireDeviceMapperC.OneWireMaster -> BasicOneWireBusC.OneWireMaster;
  OneWireDeviceMapperC.Resource ->
			BasicOneWireBusC.Resource[MAPPER_CLIENT_ID];
}
