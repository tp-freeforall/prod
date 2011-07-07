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

/** Defines types and constants related to network interfaces that may
 * be processed by code outside the OSIAN IP stack.
 *
 * (In other words, where people might not think to include <net/if.h>.)
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
#ifndef NetworkInterface_H_
#define NetworkInterface_H_

/** A type used to encode the state of a network interface. */
typedef uint8_t oip_nic_state_t;

/** Flags indicating the state of a network interface. */
enum {
  /** If set, the interface is available for use */
  IFF_UP            = 0x01,

  /** If set, the interface is a point-to-point link */
  IFF_POINTTOPOINT  = 0x02,

  /** If set, the interface does not filter incoming packets based on
   * whether their destination is an address bound to the interface.
   * All packets received are processed. */
  IFF_PROMISC       = 0x04,

  /** The interface is invalid */
  IFF_INVALID       = 0x80,
};

#endif /* NetworkInterface_H_ */
