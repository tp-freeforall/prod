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

/** Component to automatically assign the IEEE 802.15.4 link-layer address
 * based on a PAN id and the device's unique identifier.
 *
 * Instantiate this component in your configuration.  Connect
 * something (probably in MainC) to either Boot or Init.  If you use
 * Boot, your application may start running before the address is
 * configured.  If you use Init, your application may receive
 * Ieee154Address.changed() events before the boot sequence is
 * complete.  Pick your poison.
 *
 * @param PAN_ID The Personal Area Network ID to be assigned to the
 * radio interface.
 *
 * @author Peter A. Bigot
 */
generic configuration Ieee154OdiAddressC (uint16_t PAN_ID) {
  uses {
    interface Boot;
  }
  provides {
    interface Init;
    interface Ieee154Address;
  }
} implementation {
  components new Ieee154OdiAddressP(PAN_ID);
  Boot = Ieee154OdiAddressP;
  Init = Ieee154OdiAddressP;

  components Ieee154AddressC;
  Ieee154OdiAddressP.Ieee154Address -> Ieee154AddressC;
  Ieee154Address = Ieee154AddressC;

  components DeviceIdentityC;
  Ieee154OdiAddressP.DeviceIdentity -> DeviceIdentityC;
}
