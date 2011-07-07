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

#ifndef OSIAN_OIP_OIP_SOCKET_H_
#define OSIAN_OIP_OIP_SOCKET_H_

#define UQ_OIP_SOCKET "OIP.Socket"
#define UQ_OIP_UDP_SOCKET "OIP.Udp.Socket"

enum {
  /** Number of sockets in the system */
  OIP_SOCKETS_MAX = uniqueCount(UQ_OIP_SOCKET),
  /** Number of UDP sockets in the system */
  OIP_UDP_SOCKETS_MAX = uniqueCount(UQ_OIP_UDP_SOCKET),
};

#ifndef OIP_GROUPS_PER_SOCKET_MAX
/** Maximum number of multicast groups to which a socket can join.
 *
 * One is generally sufficient for non-raw sockets, since IP delivery
 * requires that the socket also bind to that group.  Raw sockets,
 * which see all packets delivered to the NIC, may desire to join
 * multiple groups, in which case this value must be increased from
 * its default. */
#define OIP_GROUPS_PER_SOCKET_MAX 1
#endif /* OIP_GROUPS_PER_SOCKET_MAX */

#endif /* OSIAN_OIP_OIP_SOCKET_H_ */
