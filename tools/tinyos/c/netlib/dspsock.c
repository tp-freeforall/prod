/*
 * Copyright 2011, Eric B. Decker
 * All rights reserved
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
 * - Neither the name of the copyright holder nor the names of
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

#include <stdint.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#include "netlib.h"

#ifndef AF_AM
#define AF_AM 20
#endif


#define MAX_AF_STR 6

char *
af2str(int af) {
  switch(af) {
    case AF_INET:	return "ipv4";
    case AF_INET6:	return "ipv6";
    case AF_UNIX:	return "unix";
    case AF_AM:		return "am";
    case AF_UNSPEC:	return "unspec";
    default:		return "none";
  }
}


#define MAX_SOCKTYPE_STR 6

char *
socktype2str(int sock_type) {
  switch(sock_type) {
    case SOCK_STREAM:	return "stream";
    case SOCK_DGRAM:	return "dgram";
    case SOCK_RAW:	return "raw";
    default:		return "none";
  }
}


#define MAX_SOCKPROTO_STR 4

char *
sockproto2str(int sock_proto) {
  switch(sock_proto) {
    case IPPROTO_UDP:	return "udp";
    case IPPROTO_TCP:	return "tcp";
    case IPPROTO_RAW:	return "raw";
    default:		return "none";
  }
}


char *
ai2str(struct addrinfo *ai) {
  static char buff[256];

  if (!ai)
    return "";
  snprintf(buff, 256, "[%-*s %-*s %-*s %s (%2d %2d %2d 0x%02x)]",
	   MAX_AF_STR,        af2str(ai->ai_family),
	   MAX_SOCKTYPE_STR,  socktype2str(ai->ai_socktype),
	   MAX_SOCKPROTO_STR, sockproto2str(ai->ai_protocol),
	   Sock_ntop(ai->ai_addr, ai->ai_addrlen),
	   ai->ai_family, ai->ai_socktype,  ai->ai_protocol, ai->ai_flags);
  return buff;
}
