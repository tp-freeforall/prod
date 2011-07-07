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

#ifndef OSIAN_OIP_SYS_SOCKET_H_
#define OSIAN_OIP_SYS_SOCKET_H_

#include <stdint.h>
#include <sys/uio.h>

/* NB: These are not the IANA values.  Nobody's OS seems to use the
 * IANA values. */
enum {
 AF_UNSPEC = 0,
 AF_INET = 4,                   /* sockaddr_in */
 AF_INET6 = 6,                  /* sockaddr_in6 */
 AF_IEEE802154 = 15,            /*  */
 AF_LOWPAN_IPHC = 32,           /*  */
};

enum {
  SOCK_STREAM = 1,
  SOCK_DGRAM = 2,
  SOCK_RAW = 3,
};

/** @note POSIX says this has to be 32-bits wide.  Not on this
 * architecture; besides, it was always supposed to be int. */
typedef int socklen_t;

typedef uint16_t sa_family_t;

struct sockaddr {
  sa_family_t sa_family;
  char sa_data[1];
};

struct sockaddr_storage {
  sa_family_t ss_family;
  char ss_data[2+4+4+16];
};

struct msghdr {
  void* msg_name;
  socklen_t msg_namelen;
  struct iovec* msg_iov;
  int msg_iovlen;
  void* msg_control;
  socklen_t msg_controllen;
  int msg_flags;
  /* Non-standard fields used for OIP */
  void* xmsg_sname;
};

extern const char* getnameinfo (const struct sockaddr* addr);

/* Socket option levels.  Values below 256 are reserved to identify
 * protocols (e.g., IPPROTO_IPV6). */
enum {
  SOL_SOCKET = 256,
  SOL_LINK,
};

/* Socket options */
enum {
  SO_TYPE = 1,
};


#endif /* OSIAN_OIP_SYS_SOCKET_H_ */
