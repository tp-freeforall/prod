/*
 * Copyright (c) 2011 Eric B. Decker.
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


#ifndef __MOTENET_H__
#define __MOTENET_H__

#include <stdint.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

#include <netlib.h>
#include <sfsource.h>
#include <serialsource.h>

#ifdef __cplusplus
//extern "C" {
#endif

/*
 * The MOTECOM environment variable can be used to automatically
 * select how to connect to the mote network.  It can take a number
 * of forms:
 *
 * AM addressing:
 *    serial@<dev>:<baud>,  ie.  serial@/dev/ttyUSB0:115200
 *    server@<host>:<port>, ie.  server@localhost:9001
 *    sf@<host>:<port>,          backward compatibility
 *
 * AM addressing is used when there is an intermediary gateway
 * to an AM based WSN.
 *
 * IPv6 addressing:
 *     <ipv6>:<port>,		 [fe80::0001]:9001
 *     <ipv6>%<scope>@<port>	 [fe80::0001%ppp0]:9001
 *
 * Direct addressing assumes that the WSN (the motenet) is running
 * an ipv6 6lowpan network that we can get to from this node via
 * native ipv6 routing.   The destination node:port then specifies
 * communications directly with that node.
 */

typedef enum {
  MCS_NONE   = 0,			/* indicate empty */
  MCS_DIRECT = 1,
  MCS_SERVER = 2,
  MCS_SERIAL = 3,
} mcs_enum_t;				/* motecom src (mcs) */


#ifndef AF_AM
#define AF_AM 20
#endif

/*
 * sam_addr is stored big endian (network order).
 * sam_grp is group, 0 -> unspecified (matches all)
 * sam_type is the AM type (similar to port), 0x00 -> unspecified (matches all)
 *
 * IP network connections have both an IP address and port so are always specified
 * by the 4 tuple (dest ip, dest port, src ip, src port).
 *
 * The AM protocol header only makes room for a single type field.  This field denotes
 * the type of the data carried in the payload, akin to the server's port.
 * The mapping to the ip 4-tuple is (dst am, type, src am, type).
 *
 * We use socket structures to represent the end points.  Bind sets the
 * local end point and Connect sets the remote.   Grp and Type should match for local
 * and remote to be consistant with the AM specification but we don't explicitly
 * check for this.
 */
struct sockaddr_am {
  __SOCKADDR_COMMON (sam_);		/* sam_family */
  uint16_t sam_addr;			/* network order */
  uint8_t  sam_grp;
  uint8_t  sam_type;			/* equiv to port */
};


#define MC_DEV_SIZE  32
#define MC_BAUD_SIZE 16
#define MC_CONN_SIZE 80

typedef struct {
  mcs_enum_t mc_src;
  struct addrinfo *ai;			/* gw/server addr */
  char dev[MC_DEV_SIZE];
  char baud[MC_BAUD_SIZE];
  char conn_str[MC_CONN_SIZE];		/* original connection string */
  serial_source serial_src;
  struct sockaddr_am am_local;
  struct sockaddr_am am_remote;
  int                sock_fd;		/* fd for direct/server socket */
  int                family;
  enum __socket_type socktype;
} motecom_conn_t;


int   mn_debug_set(int val);
int   mn_debug_get();

int   mn_parse_motecom(motecom_conn_t *mcs, char *conn_str);
char *mn_mcs2str(motecom_conn_t *mcs, char *str, size_t str_size);
int   mn_socket(motecom_conn_t *mcs, int domain, int type, int protocol);
int   mn_bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
int   mn_connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
int   mn_close(int sockfd);

ssize_t mn_send(int sockfd, const void *buf, size_t len, int flags);
ssize_t mn_sendto(int sockfd, const void *buf, size_t len, int flags,
		  const struct sockaddr *dest_addr, socklen_t addrlen);

ssize_t mn_recv(int sockfd, void *buf, size_t len, int flags);
ssize_t mn_recvfrom(int sockfd, void *buf, size_t len, int flags,
		    struct sockaddr *src_addr, socklen_t *addrlen);

#ifdef __cplusplus
//}
#endif

#endif		/* __MOTENET_H__ */
