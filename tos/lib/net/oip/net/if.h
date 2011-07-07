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

#ifndef OSIAN_OIP_OIP_IF_H_
#define OSIAN_OIP_OIP_IF_H_

#include <stdint.h>

/** Represent a network interface identifier.
 *
 * A value of zero indicates an undefined NIC.  Positive values
 * identify specific NIC instances.  A negative value indicates an
 * error. */
typedef int8_t oip_network_id_t;

#define UQ_OIP_NETWORK_INTERFACE "OIP.NetworkInterface"

enum {
  /** Number of network interfaces in the system, which also doubles
   * as the maximum valid interface index, since interface indexes
   * start at 1. */
  OIP_NETWORK_INTERFACE_MAX = uniqueCount(UQ_OIP_NETWORK_INTERFACE),
};

#ifndef OIP_ADDRESSES_PER_NIC
/** Maximum number of addresses assigned to any NIC.  Examples:
 * - Link layer address
 * - IPv6 link local address (fe80::<oid>)
 * - IPv6 link layer address (<ula>:<pan_id>::<short_addr>)
 * - IPv6 site address (<ula>:<osian>::<oid>)
 * - IPv6 global address (??)
 */
#define OIP_ADDRESSES_PER_NIC 5
#endif /* OIP_ADDRESSES_PER_NIC */

#ifndef OIP_GROUPS_PER_NIC
/** Maximum number of multicast groups that can be joined on any NIC.
 * Solicited node addresses, and the all nodes (routers) addresses do
 * not count against this limit. */
#define OIP_GROUPS_PER_NIC 4
#endif /* OIP_GROUPS_PER_NIC */

#include "NetworkInterface.h"

#endif /* OSIAN_OIP_OIP_IF_H_ */
