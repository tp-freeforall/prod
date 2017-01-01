/*
 * Copyright 2011, Eric B. Decker
 * All rights reserved
 *
 * MoteNet: Provide a sockets interface for TinyOS network traffic.
 *
 * In server or serial mode, motenet provides a sockets interface to
 * traffic using the AM (Active Message) light weight protocol.  A gateway
 * between IP (either IPv4 or IPv6) and the AM motenet needs to be
 * running at the interface between the different networks.  This
 * transition occurs at the node with the serial network interface
 * to the motenet.
 *
 * In direct mode, the motenet is assumed to be running an IPv6 network
 * stack.  Interconnect at the WSN/Main network interface needs to be
 * running IPv6 gateway software such as a PPP capable bridge.  So an
 * application using the socket interface can connect to any node in
 * the WSN domain handled by the gateway.
 *
 * The MoteNet interface is intended to allow construction of network
 * applications that will work with zero or minimal changes when connecting
 * to nodes on an AM network or on a 6lowpan network using standard socket
 * network programming methods.
 *
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

#include <sys/types.h>
#include <stdint.h>
#include <ctype.h>
#include <errno.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <netlib.h>
#include <serialsource.h>
#include <sfsource.h>
#include "am.h"
#include "motenet.h"

int mn_debug = 0;

/* max buffer size for copying strings from a motecom connection string */
#define MCS_MAX_BUF 256


/*
 * We need to provide a intervention layer in between data below us
 * and the application layer.  This allows us to handle normal
 * sockets talking directly to the network layer as well as emulating
 * the network layer handling AM encapsulated packets.
 *
 * AM packets are handled either directly (SERIAL) or via a Serial
 * Forwarder.   A motecomm_connection structure (mcs) is used to
 * keep track of information needed to provide the switching needed.
 * The MCS is provided by the client and is considered opaque to the
 * application.  We maintain a table that cross references the file
 * descriptor returned by the system  to the corresponding MCS.
 */

typedef struct {
  int fd;
  motecom_conn_t *mcs;
} fd_mcs_t;


#define MAX_FD_MCS 5

static fd_mcs_t mn_fd_mcs[MAX_FD_MCS];		/* init's to NULL */


static char *msgs[] = {
  "unknown_packet_type",
  "ack_timeout"	,
  "sync"	,
  "too_long"	,
  "too_short"	,
  "bad_sync"	,
  "bad_crc"	,
  "closed"	,
  "no_memory"	,
  "unix_error"
};


void __mn_serial_msg(serial_source_msg problem) {
  fprintf(stderr, "*** Note: %s\n", msgs[problem]);
}


int
mn_debug_set(int val) {
  int ret;

  ret = mn_debug;
  mn_debug = val;
  return ret;
}


int
mn_debug_get() {
  return mn_debug;
}


/*
 * strip in place any white space preceeding or trailing
 * the string.
 *
 * returns:	pointer to new start.
 *
 * any whitespace on the end of the string will be stripped.  A
 * new eol will be laid down at the end of pertinent bits.
 */

char *
strip_white(char *s) {
  char *p;
  int len;

  p = s;
  while(*p && isspace(*p))
    p++;
  s = p;
  len = strlen(s);
  if (len > 0) {
    p = &s[len-1];
    while(*p && isspace(*p))
      p--;
    *(p+1) = 0;
  }
  return s;
}


/*
 * parse_host_port:
 *
 * parse out host and port portions of the input string.
 * two fields, host and port seperated by : .
 *
 * WARNING: source string is modified in place.
 *
 * h,p <- parse(s)
 *
 * input:  h	ptr to char ptr, for host resultant
 *         p	ptr to char ptr, for port resultant
 *	   s	char ptr to string to parse
 *
 * output: ret	0  parse complete
 *	        1  oops.   failed.  something wrong.
 *         *h   h filled in, points at host part
 *         *p   p filled in, points at port part
 *
 * Original string is modified to 0 terminate found parts.
 * h and p point into original string buffer.
 */

int
parse_host_port(char **h, char **p, char *s) {
  char *hp, *pp, *t;

  hp = s;
  t = strrchr(hp, ':');		/* rev search for port seperator */
  if (t == NULL)
    return 1;			/* must be present. */
  pp = t + 1;
  *t = 0;			/* terminate host str */

  hp = strip_white(hp);		/* kill any imbedded white space */
  pp = strip_white(pp);

  /* check for ipv6 explicit address in "[]" */
  if (hp[0] == '[')
    hp++;
  t = &hp[strlen(hp)-1];
  if (*t == ']')
    *t = 0;
  hp = strip_white(hp);

  *h = hp;
  *p = pp;
  return 0;
}


int
lookup_host_port(motecom_conn_t *mcs, char *hp, char *pp, int sock_type) {
  int err;
  struct addrinfo hints, *res;

  memset(&hints, 0, sizeof(hints));
  hints.ai_flags    = (AI_V4MAPPED | AI_ADDRCONFIG);
  hints.ai_family   = AF_UNSPEC;
  hints.ai_socktype = sock_type;
  err = getaddrinfo(hp, pp, &hints, &res);
  if (err) {
    fprintf(stderr, "\n*** motenet: gai: \"%s:%s\": %s (%d)\n", hp, pp,
	    gai_strerror(err), err);
    return 1;
  }
  mcs->ai = res;
  if (mn_debug) {
    fprintf(stderr, "\n");
    while (res) {
      fprintf(stderr, "%s\n", ai2str(res));
      res = res->ai_next;
    }
  }
  return 0;
}


/*
 * MoteNet Parse MOTECOM.
 *
 * parse a connection string yielding a connection structure.
 *
 * input:	mcs	pointer to a connection structure.  Result of the
 *			parse are stored here.
 *
 *		conn_str provided string to parse.  Can be NULL or empty.
 *
 * returns:	0	parsing succeeded, mcs updated with connection data.
 *		1	failed to parse. indicate failure.
 *
 * Source string can be passed in or can be obtained from the environment
 * variable MOTECOM.  Passed in string takes priority but only if not empty.
 *
 * Formats:
 *
 *    <host>:<port>
 *    server@<host>:<port>
 *    sf@<host>:<port>
 *    serial@<dev>:<baud>
 *
 *    <host> can be an IPv4 or IPv6 literal address or host name.  Host name
 *    will be looked up using DNS.   AAAA will yield ipv6 addresses, AA will
 *    yield ipv4 addresses.   IPv4 literals should be specified in dotted
 *    quads.  IPv6 literals are specified using IPv6 colon nomenclature and
 *    must be specified inside of "[]" like ipv6 URLs.
 *
 * Examples:
 *
 *    zot:9001, localhost:9001, 127.0.0.1:9001
 *
 *    serial@/dev/ttyUSB1:115200, serial@COM1:9600
 *
 *    server@zot:9001, sf@zot:9001, server@localhost:9001,
 *    server@192.168.1.100:9001, etc.
 *
 *    [fe80::fd41:4242:e88:3]:9001, device.ppp.osian:9001
 *    server@[fe80::fd41:4242:e88:2]:9001, server@host.ppp.osian:9001
 *
 *    port can also be specified by using service name.
 */

int
mn_parse_motecom(motecom_conn_t *mcs, char *conn_str) {
  char cs[MCS_MAX_BUF];			/* conn str copy */
  char *ctp;				/* conn type pointer */
  char *hp, *pp;			/* host and port pointer */
  char *p;

  if (!mcs)
    return 1;

  p = NULL;				/* p is where we are starting. */
  memset(mcs, 0, sizeof(motecom_conn_t));
  if (conn_str) {
    /*
     * connection string specified (non-NULL), make sure it says something.
     */
    strncpy(cs, conn_str, MCS_MAX_BUF);
    p = strip_white(cs);
    strncpy(mcs->conn_str, p, MC_CONN_SIZE);
    if (strlen(p) == 0)
      p = NULL;
  }
  if (p == NULL) {			/* if still NULL, no connection string */
    /*
     * haven't found something to work on yet.   So see if we can
     * find something in the environment variable MOTECOM.
     */
    p = getenv("MOTECOM");
    if (p == NULL)			/* MOTECOM not found, bail */
      return 1;
    strncpy(cs, p, MCS_MAX_BUF);	/* make our own copy */
    p = strip_white(cs);
    strncpy(mcs->conn_str, p, MC_CONN_SIZE);
    if (strlen(p) == 0)
      p = NULL;
  }
  if (p == NULL)			/* still nothing to work on, bail */
    return 1;

  /*
   * something to work on.
   *
   * See if we can find a connection type,  Look for @
   */
  ctp = p;
  p = strchr(ctp, '@');
  if (p == NULL) {
    /*
     * @ not found --> must be DIRECT
     */
    mcs->mc_src = MCS_DIRECT;
    if (parse_host_port(&hp, &pp, ctp))
      return 1;				/* parse didn't work, bail */
    ctp = NULL;				/* no connection type */

    return lookup_host_port(mcs, hp, pp, SOCK_DGRAM);
  }

  /*
   * @ found.  Look for "server", "sf", or "serial".
   */
  hp = p+1;				/* move beyond the connection type */
  *p = 0;				/* isolate the connection type */

  ctp = strip_white(ctp);
  if ((strcmp(ctp, "server") == 0) || (strcmp(ctp, "sf") == 0)) {
    mcs->mc_src = MCS_SERVER;
    if (parse_host_port(&hp, &pp, hp))
      return 1;
    return lookup_host_port(mcs, hp, pp, SOCK_STREAM);
  } else if (strcmp(ctp, "serial") == 0) {
    /*
     * serial@/dev/ttyUSB1:115200, use parse_host_port to find
     * device (host) and baud (port).  Same algorithm.
     */
    mcs->mc_src = MCS_SERIAL;
    if (parse_host_port(&hp, &pp, hp))
      return 1;
    strncpy(mcs->dev,  hp, MC_DEV_SIZE);
    strncpy(mcs->baud, pp, MC_BAUD_SIZE);
    return 0;
  }
  fprintf(stderr, "\n*** motenet: unrecognized connection type: %s\n", ctp);
  return 1;
}


char *
mn_mcs2str(motecom_conn_t *mcs, char *str, size_t str_size) {
  size_t space_avail, added;
  char *cur;
  struct addrinfo *ai;

  if (!str || str_size == 0)
    return NULL;
  if (!mcs) {
    str[0]=0;
    return str;
  }
  space_avail = str_size;
  cur = str;
  added = snprintf(cur, space_avail, "(%s) ", mcs->conn_str);
  space_avail -= added;
  cur += added;
  switch (mcs->mc_src) {
    case MCS_DIRECT:
    case MCS_SERVER:
      added = snprintf(cur, space_avail, "%s@",
		       (mcs->mc_src == MCS_DIRECT ? "direct" : "server"));
      space_avail -= added;
      cur += added;
      ai = mcs->ai;
      while (ai) {
	added = snprintf(cur, space_avail, "<%s>",
			 Sock_ntop(ai->ai_addr, ai->ai_addrlen));
	space_avail -= added;
	cur += added;
	ai = ai->ai_next;
      }
      return str;

    case MCS_SERIAL:
      added = snprintf(cur, space_avail, "serial@%s:%s",
		       mcs->dev, mcs->baud);
      space_avail -= added;
      cur += added;
      return str;

    default:
      added = snprintf(cur, space_avail, "unknown, %d",
		       mcs->mc_src);
      space_avail -= added;
      cur += added;
      return str;
  }
}


static int
open_mn_sf_source(motecom_conn_t *mcs) {
  int fd, err;
  struct addrinfo *aip;

  if (!mcs) {
    errno = EINVAL;
    return -1;
  }
  aip = mcs->ai;
  fd = socket(aip->ai_family, aip->ai_socktype, 0);
  if (fd < 0) {
    fprintf(stderr, "motenet: socket (server open): %s (%d) (%s)\n",
	    strerror(errno), errno, mcs->conn_str);
    return fd;
  }

  mcs->sock_fd = fd;
  err = connect(fd, aip->ai_addr, aip->ai_addrlen);
  if (err < 0) {
    fprintf(stderr, "motenet: %s connect (server) %s (%d) (%s)\n",
	    Sock_ntop(aip->ai_addr, aip->ai_addrlen),
	    strerror(errno), errno, mcs->conn_str);
    close(fd);
    return -1;
  }
  if (init_sf_source(fd) < 0) {
    fprintf(stderr, "motenet: init_sf failed.  (%s)\n", mcs->conn_str);
    close(fd);
    errno = EUNATCH;
    return -1;
  }
  return fd;
}


int
mn_socket(motecom_conn_t *mcs, int domain, int type, int protocol) {
  int i, fd;
  fd_mcs_t *slot;
  struct addrinfo *aip;

  if (!mcs) {
    errno = EINVAL;
    return -1;
  }
  slot = NULL;
  for (i = 0; i < MAX_FD_MCS; i++) {
    if (mn_fd_mcs[i].mcs == NULL) {
      slot = &mn_fd_mcs[i];
      break;
    }
  }
  if (slot == NULL) {
    errno = ENOBUFS;
    return -1;
  }
  switch(mcs->mc_src) {
    case MCS_DIRECT:
      aip = mcs->ai;
      fd = socket(aip->ai_family, aip->ai_socktype, 0);
      if (fd < 0) {
	fprintf(stderr, "motenet: socket (direct): %s (%d) (%s)\n", strerror(errno), errno, mcs->conn_str);
	return fd;
      }
      slot->fd = fd;
      break;

    case MCS_SERVER:
      fd = open_mn_sf_source(mcs);
      if (fd < 0) {
	fprintf(stderr, "motenet: socket (server): %s (%d) (%s)\n", strerror(errno), errno, mcs->conn_str);
	return fd;
      }
      slot->fd = fd;
      mcs->sock_fd = fd;
      break;

    case MCS_SERIAL:
      errno = 0;
      mcs->serial_src = open_serial_source(mcs->dev, platform_baud_rate(mcs->baud),
					   0, __mn_serial_msg);
      if (mcs->serial_src == NULL) {
	if (errno == 0)
	  errno = EINVAL;
	fprintf(stderr, "motenet: socket (serial open): %s (%d) (%s)\n", strerror(errno), errno, mcs->conn_str);
	return -1;
      }
      fd = serial_source_fd(mcs->serial_src);
      slot->fd = fd;
      break;

    default:
      errno = EINVAL;
      return -1;
  }
  slot->mcs = mcs;
  mcs->family = domain;
  mcs->socktype = type;
  return fd;
}


static motecom_conn_t *
find_mcs(int fd) {
  int i;

  for (i = 0; i < MAX_FD_MCS; i++) {
    if (mn_fd_mcs[i].fd == fd)
      return mn_fd_mcs[i].mcs;
  }
  return NULL;
}


int
mn_bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen) {
  motecom_conn_t *mcs;
  struct sockaddr_am *am_addr;

  mcs = find_mcs(sockfd);
  if (!mcs) {
    errno = EINVAL;
    return -1;
  }
  if (mcs->mc_src == MCS_DIRECT)
    return bind(sockfd, addr, addrlen);

  if (mcs->mc_src != MCS_SERVER && mcs->mc_src != MCS_SERIAL) {
      errno = EINVAL;
      return -1;
  }

  am_addr = (struct sockaddr_am *) addr;
  if (am_addr->sam_family != AF_AM) {
    errno = EINVAL;
    return -1;
  }
  memcpy(&mcs->am_local, am_addr, sizeof(struct sockaddr_am));
  return 0;
}


int
mn_connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen) {
  motecom_conn_t *mcs;
  struct sockaddr_am *am_addr;

  mcs = find_mcs(sockfd);
  if (!mcs) {
    errno = EINVAL;
    return -1;
  }
  if (mcs->mc_src == MCS_DIRECT)
    return connect(sockfd, addr, addrlen);

  if (mcs->mc_src != MCS_SERVER && mcs->mc_src != MCS_SERIAL) {
      errno = EINVAL;
      return -1;
  }

  am_addr = (struct sockaddr_am *) addr;
  if (am_addr->sam_family != AF_AM) {
    errno = EINVAL;
    return -1;
  }
  memcpy(&mcs->am_remote, am_addr, sizeof(struct sockaddr_am));
  return 0;
}


int
mn_close(int sockfd) {
  int ret;
  motecom_conn_t *mcs;

  mcs = find_mcs(sockfd);
  if (!mcs) {
    errno = EINVAL;
    return -1;
  }
  if (mcs->ai) {
    freeaddrinfo(mcs->ai);
    mcs->ai = NULL;
  }
  switch (mcs->mc_src) {
    case MCS_DIRECT:
      return close(sockfd);

    case MCS_SERVER:
      ret = close(mcs->sock_fd);
      mcs->sock_fd = 0;
      return ret;

    case MCS_SERIAL:
      ret = close_serial_source(mcs->serial_src);
      mcs->serial_src = NULL;
      return ret;

    default:
      errno = EINVAL;
      return -1;
  }
}


static ssize_t
am_send_packet(motecom_conn_t *mcs, struct sockaddr_am *am_dest,
	       const void *buf, size_t len) {
  void *packet;
  int out_len, i;
  am_hdr_t *amh;			/* am header in packet */
  struct sockaddr_am *aml;		/* our local information */

  packet = malloc(len + AM_HDR_LEN);
  if (!packet) {
    errno = ENOMEM;
    return -1;
  }

  /*
   * Add a header if needed....   RAW is assumed to be properly constructed.
   * DGRAM needs the header put on the front.
   */
  switch(mcs->socktype) {
    case SOCK_RAW:
      memcpy(packet, buf, len);
      out_len = len;
      break;

    case SOCK_DGRAM:
      if (!am_dest || am_dest->sam_family != AF_AM) {
	errno = EINVAL;
	free(packet);
	return -1;
      }
      amh = packet;
      aml = &mcs->am_local;
      if (mn_debug && aml->sam_type == 0)
	fprintf(stderr, "*** warning: send with local_type set to 0\n");
      amh->am_encap = AM_ENCAP_BASIC;
      amh->am_dest  = am_dest->sam_addr; /* dest, already network order */
      amh->am_src   = aml->sam_addr;	 /* src, us, network order */
      amh->am_len   = len;
      amh->am_grp   = aml->sam_grp;	 /* should be the same, local overrides */
      amh->am_type  = aml->sam_type;	 /* local remote should be same */
      memcpy(packet + AM_HDR_LEN, buf, len);
      out_len = len + AM_HDR_LEN;
      break;

    default:
      errno = EINVAL;
      free(packet);
      return -1;
  }

  if (mn_debug) {
    amh = packet;
    fprintf(stderr, "%04x:%d (%02x) (l: %d): ", ntohs(amh->am_dest),
	    amh->am_type, amh->am_type, out_len);
    for (i = 0; i < out_len; i++)
      fprintf(stderr, "%02x ", ((uint8_t *) packet)[i]);
    fprintf(stderr, "\n");
  }

  switch(mcs->mc_src) {
    case MCS_SERVER: write_sf_packet(mcs->sock_fd, packet, out_len);      break;
    case MCS_SERIAL: write_serial_packet(mcs->serial_src, packet, out_len); break;
    default:
      errno = EINVAL;
      free(packet);
      return -1;
  }
  free(packet);
  return out_len;
}


ssize_t
mn_sendto(int sockfd, const void *buf, size_t len, int flags,
	      const struct sockaddr *dest_addr, socklen_t addrlen){
  motecom_conn_t *mcs;
  int out_len;
  struct sockaddr_am *dst;

  mcs = find_mcs(sockfd);
  if (!mcs || !buf || !len) {
    errno = EINVAL;
    return -1;
  }

  if (mcs->mc_src == MCS_DIRECT)
    return send(sockfd, buf, len, flags);

  if (dest_addr)
    dst = (struct sockaddr_am *) dest_addr;
  else
    dst = &mcs->am_remote;
  out_len = am_send_packet(mcs, dst, buf, len);
  return out_len;
}


ssize_t
mn_send(int sockfd, const void *buf, size_t len, int flags) {
  motecom_conn_t *mcs;
  int out_len;

  mcs = find_mcs(sockfd);
  if (!mcs || !buf || !len) {
    errno = EINVAL;
    return -1;
  }

  if (mcs->mc_src == MCS_DIRECT)
    return send(sockfd, buf, len, flags);

  out_len = am_send_packet(mcs, &mcs->am_remote, buf, len);
  return out_len;
}


/*
 * receive an AM packet with filtering from AM lower layer
 *
 * Receive an AM packet from either the server or serial with
 * input filtering (dest address, group, type).
 */

static void *
am_recv_packet(motecom_conn_t *mcs, int *len) {
  uint8_t *packet;
  am_hdr_t *amh;			/* am header in packet */
  struct sockaddr_am *aml;		/* our local information */

  if (mcs == NULL || len == NULL)
    return NULL;

  do {
    switch (mcs->mc_src) {
      case MCS_SERVER:	packet = read_sf_packet(mcs->sock_fd, len);      break;
      case MCS_SERIAL:	packet = read_serial_packet(mcs->serial_src, len); break;
      default: return NULL;
    }

    if (packet == NULL)
      return NULL;

    /*
     * SOCK_RAW returns raw protocol information, which is the
     * uninterpreted data. No address checks, or type checks, etc. are
     * done.
     */
    if (mcs->socktype == SOCK_RAW)
      return packet;

    amh = (am_hdr_t *) packet;
    aml = &mcs->am_local;

    /* ignore encaps we don't understand. */
    if (amh->am_encap != AM_ENCAP_BASIC &&
	amh->am_encap != AM_ENCAP_LEN16) {
      free(packet);
      continue;
    }

    /*
     * accept bcast, we're set for any, or its pointed at us
     * otherwise kick to next packet.
     */
    if ((amh->am_dest  != AM_ADDR_BCAST) &&
	(aml->sam_addr != AM_ADDR_ANY)   &&
	(aml->sam_addr != amh->am_dest)) {
      free(packet);
      continue;
    }

    if ((aml->sam_grp != AM_GRP_ANY) &&
	(aml->sam_grp != amh->am_grp)) {
      free(packet);
      continue;
    }

    if ((aml->sam_type != AM_TYPE_ANY) &&
	(aml->sam_type != amh->am_type)) {
      free(packet);
      continue;
    }
    break;				/* accept the packet */
  } while (1);

  return packet;
}


/*
 * mn_recv: receive on a socket
 *
 * input: sockfd	socket file descriptor to receive on
 *			must be registered in the fd_mcs database (via mn_socket)
 *	  buf		buffer to receive into.
 *	  len		max size of buf
 *	  flags		flags for receive (see recvfrom(2)),  currently not implemented
 *
 * Receive a motenet packet into the buffer pointed to by BUF.  LEN indicates
 * the maximum size of the buffer BUF.  If the packet data coming in is too
 * large to fit into buf, the receive will still occuur upto the maximum size
 * LEN.  Any remaining packet data will be lost.
 */

ssize_t
mn_recv(int sockfd, void *buf, size_t len, int flags) {
  motecom_conn_t *mcs;
  uint8_t *packet;
  int in_len;

  mcs = find_mcs(sockfd);
  if (!mcs || !buf || !len) {
    errno = EINVAL;
    return -1;
  }

  /*
   * DIRECT uses built in filtering dependent on socktype.
   * In other words, let the kernel do it.
   */
  if (mcs->mc_src == MCS_DIRECT)
    return recv(sockfd, buf, len, flags);

  if (mcs->socktype != SOCK_DGRAM && mcs->socktype != SOCK_RAW) {
    errno = EINVAL;
    return -1;
  }

  packet = am_recv_packet(mcs, &in_len);
  if (packet == NULL)
    return 0;

  if (mcs->socktype == SOCK_RAW) {    /* if RAW, return full packet */
    if (len < in_len)
      in_len = len;
    memcpy(buf, packet, in_len);
    free(packet);
    return in_len;
  }

  /*
   * strip off the header and just return the data
   */
  in_len -= AM_HDR_LEN;
  if (len < in_len)
    in_len = len;
  memcpy(buf, packet + AM_HDR_LEN, in_len);
  free(packet);
  return in_len;
}


/*
 * mn_recvfrom: receive on a socket returning packet source.
 *
 * input: sockfd	socket file descriptor to receive on
 *			must be registered in the fd_mcs database (via mn_socket)
 *	  buf		buffer to receive into.
 *	  len		max size of buf
 *	  flags		flags for receive (see recvfrom(2)),  currently not implemented
 *	  src_addr	pointer to a sockaddr structure, used to fill in the
 *			if provided.  NULL says do not use.
 *	  addrlen	pointer to the size of the src_addr structure.  On input
 *			indicates maximum size of *src_addr.  On output how
 *			big the data written into *src_addr is.
 *
 * Receive a motenet packet into the buffer pointed to by BUF.  LEN indicates
 * the maximum size of the buffer BUF.  If the packet data coming in is too
 * large to fit into buf, the receive will still occuur upto the maximum size
 * LEN.  Any remaining packet data will be lost.
 *
 * If src_addr is non-NULL, then the source address of the incoming AM packet
 * will be copied into the structure pointed to by SRC_ADDR.  ADDRLEN indicates
 * the maximum size of the data area available for SRC_ADDR.  If the size of
 * data being written into SRC_ADDR is larger than ADDRLEN, only the data that
 * will fit will be written.  Any additional data will be lost.  ADDRLEN will
 * be updated on return to indicate the size of the data area needed to contain
 * the full address.
 */

ssize_t
mn_recvfrom(int sockfd, void *buf, size_t len, int flags,
	 struct sockaddr *src_addr, socklen_t *addrlen) {
  motecom_conn_t *mcs;
  void *packet;
  int in_len;
  am_hdr_t *amh;
  struct sockaddr_am *ama, am_addr;

  mcs = find_mcs(sockfd);
  if (!mcs || !buf || !len) {
    errno = EINVAL;
    return -1;
  }

  /*
   * DIRECT uses built in filtering dependent on socktype.
   * In other words, let the kernel do it.
   */
  if (mcs->mc_src == MCS_DIRECT)
    return recvfrom(sockfd, buf, len, flags, src_addr, addrlen);

  if (mcs->socktype != SOCK_DGRAM && mcs->socktype != SOCK_RAW) {
    errno = EINVAL;
    return -1;
  }

  packet = am_recv_packet(mcs, &in_len); /* has dest filtering */
  if (packet == NULL)
    return 0;

  /*
   * if src_addr non-NULL (requested), return the src of this packet.
   */
  amh = packet;
  ama = &am_addr;
  ama->sam_family = AF_AM;
  ama->sam_addr   = amh->am_src;	/* net order */
  ama->sam_grp    = amh->am_grp;
  ama->sam_type   = amh->am_type;

  if (src_addr != NULL && addrlen != NULL) {
    if (*addrlen > sizeof(*ama))	/* see recvfrom(2) */
      *addrlen = sizeof(*ama);
    memcpy(src_addr, ama, *addrlen);	/* copy over as much as we can. */
    *addrlen = sizeof(*ama);		/* see recvfrom(2) */
  }

  if (mcs->socktype == SOCK_RAW) {    /* if RAW, return full packet */
    if (len < in_len)
      in_len = len;
    memcpy(buf, packet, in_len);
    free(packet);
    return in_len;
  }

  /*
   * strip off the header and just return the data
   */
  in_len -= AM_HDR_LEN;
  if (len < in_len)
    in_len = len;
  memcpy(buf, packet + AM_HDR_LEN, in_len);
  free(packet);
  return in_len;
}
