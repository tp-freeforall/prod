/* Copyright (c) 2010 People Power Co.
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
 * - Neither the name of the People Power Corporation nor the names of
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
 *
 */

/** Assign an 802.15.4 address based on a device identity.
 *
 * @param PAN_ID The Personal Area Network ID to be assigned to the
 * radio interface.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
generic module Ieee154OdiAddressP (uint16_t PAN_ID) {
  uses {
    interface Boot;
    interface Ieee154Address;
    interface DeviceIdentity;
  }
  provides {
    interface Init;
  }
} implementation {

  async event void Ieee154Address.changed () { }

  command error_t Init.init ()
  {
    const ieee_eui64_t* euip = call DeviceIdentity.getEui64();
    uint8_t iid[IEEE_EUI64_LENGTH];
    ieee154_saddr_t saddr;
    
    /* Create modified EUI64 for IID */
    memcpy(iid, euip->data, sizeof(iid));
    iid[0] |= 0x02;

    /* Low two octets read, converted to host byte order, form short address */
    saddr = ntohs(*(uint16_t*)(iid + 6));

    call Ieee154Address.setAddress(PAN_ID, saddr);
    return SUCCESS;
  }

  event void Boot.booted ()
  {
    call Init.init();
  }

}
