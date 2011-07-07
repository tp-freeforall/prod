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

module DeviceModifiedEui64P {
  uses {
    interface DeviceIdentity;
  }
  provides {
    interface NetworkInterfaceIdentifier;
  }
} implementation {

  enum {
    /** Bit 7 of the EUI64 is set to indicate a modified EUI64 as used
     * as an IPv6 interface identifier */
    MODIFIED_EUI64_MARKER = 0x02,
  };

  command const uint8_t* NetworkInterfaceIdentifier.interfaceIdentifier ()
  {
    static ieee_eui64_t iid;
    if (! (iid.data[0] & MODIFIED_EUI64_MARKER)) {
      const ieee_eui64_t* odip = call DeviceIdentity.getEui64();
      if (! odip) {
        return 0;
      }
      memcpy(iid.data, odip->data, sizeof(iid));
      iid.data[0] |= MODIFIED_EUI64_MARKER;
    }
    return iid.data;
  }

  command uint8_t NetworkInterfaceIdentifier.interfaceIdentifierLength_bits () { return 64; }
}
