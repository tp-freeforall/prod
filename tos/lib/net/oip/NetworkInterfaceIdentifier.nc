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

#include <sys/socket.h>

/** Provide access to the interface identifier for a network interface.
 *
 * Generally, any NIC has exactly one identifier.  These identifiers
 * are supposedly unique within all links to which the NIC connects.
 * The identifiers are not guaranteed to be 64 bits long, though this
 * is a common situation.
 *
 * In some situations it is necessary to be able to access a second
 * identifier (in the case of PPP, to determine the IID of the
 * remote).  Hence this needs to be separate from NetworkLinkInterface
 * and other aggregate interfaces, at least until nesC supports
 * interface composition.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface NetworkInterfaceIdentifier {

  /** Return a pointer to the interface identifier.
   *
   * An interface identifier is a bit sequence of specified length,
   * expected to be unique within the link to which the interface, um,
   * interfaces.
   *
   * The identifier for an interface is presumed to be constant over
   * the period when the interface is up.  It may, however, be
   * undefined during periods when the interface is down.  As an
   * example, the identifier for a PPP NIC supporting IPv6 may be
   * determined by the lower 64 bits of the link local address
   * assigned by the remote.
   *
   * @note The number of bits in the interface identifier is 8i+n, for
   * integral values of i and n.  If n is not zero, the most
   * significant (8-n) bits of the first octet in sequence beginning
   * at the returned value are ignored for the purpose of specifying
   * the IID.  In other words, the last bit of the IID is the least
   * significant bit of the i'th octet beginning at the returned
   * address.  The values of remaining bits in that octet are
   * undefined.
   *
   * @return Pointer to the first octet of an encoded interface
   * identifier; or a null pointer if the interface has no assigned
   * identifier. */
  command const uint8_t* interfaceIdentifier ();

  /** Return the number of bits in the interface identifier.
   *
   * This value is valid only immediately following a call to
   * interfaceIDentifier() that returned a non-null pointer.  In other
   * words, the length of the interface identifier may be undefined
   * when there is no IID, and may change if the IID changes.
   *
   * @return Length, in bits, of the interface identifier
   */
  command uint8_t interfaceIdentifierLength_bits ();

}
