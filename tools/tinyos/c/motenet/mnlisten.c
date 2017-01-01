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

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <getopt.h>
#include <libgen.h>
#include <string.h>
#include <netlib.h>

#include "am.h"
#include "motenet.h"

static void usage(char *name) {
  fprintf(stderr, "usage: %s <host>:<port>\n", name);
  fprintf(stderr, "       %s server@<host>:<port>\n", name);
  fprintf(stderr, "       %s serial@<serial device>:<baud rate>\n", name);
  fprintf(stderr, "\n");
  fprintf(stderr, "    host:   <ipv4> or <ipv6> node or explicit address\n");
  fprintf(stderr, "    server: AM gateway server\n");
  fprintf(stderr, "    serial: AM serial gateway via serial port\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "    environment var MOTECOM can set the connection\n");
  fprintf(stderr, "    command line overrides MOTECOM\n");
  exit(2);
}


motecom_conn_t mcs_conn;


int
main(int argc, char **argv) {
  int fd, err;
  char *prog_name, *p;
  struct sockaddr_am *am_l,         *am_r;
  struct sockaddr_am  am_local_addr, am_remote_addr;
  socklen_t slen;
  char    buff[256];
  uint8_t pkt[1024];

  prog_name = basename(argv[0]);

  switch(argc) {
    case 1:	p = NULL;	break;
    case 2:	p = argv[1];	break;
    default:
      usage(prog_name);
  }
  mn_debug_set(1);
  if (mn_parse_motecom(&mcs_conn, p)) {
    fprintf(stderr, "\nCmd Line/MOTECOM connection string didn't parse\n");
    fprintf(stderr, "Command line: \"%s\"\n", p);
    p = getenv("MOTECOM");
    fprintf(stderr, "MOTECOM: \"%s\"\n\n", (p ? p : "not found"));
    usage(prog_name);
  }

  fprintf(stderr, "Connecting: %s\n", mn_mcs2str(&mcs_conn, buff, 256));

  am_l = &am_local_addr;
  am_l->sam_family = AF_AM;
  am_l->sam_addr   = htons(0x0001);
  am_l->sam_grp    = AM_GRP_ANY;
  am_l->sam_type   = AM_TYPE_ANY;

  am_r = &am_remote_addr;
  am_r->sam_family = AF_AM;
  am_r->sam_addr   = htons(AM_ADDR_BCAST);
  am_r->sam_grp    = AM_GRP_ANY;
  am_r->sam_type   = AM_TYPE_ANY;

  fd = mn_socket(&mcs_conn, AF_AM, SOCK_RAW, 0);
  if (fd < 0) {
    fprintf(stderr, "%s: mn_socket: %s (%d)\n", prog_name, strerror(errno), errno);
    exit(1);
  }

  /* set local side address */
  err = mn_bind(fd, (SA *) am_l, sizeof(am_local_addr));
  if (err) {
    fprintf(stderr, "%s: mn_bind: %s (%d)\n", prog_name, strerror(errno), errno);
    exit(1);
  }

  /* set remote address */
  err = mn_connect(fd, (SA *) am_r, sizeof(am_remote_addr));
  if (err) {
    fprintf(stderr, "%s: mn_connect: %s (%d)\n", prog_name, strerror(errno), errno);
    exit(1);
  }

  for (;;) {
    int len, i;

    slen = sizeof(*am_r);
    len = mn_recvfrom(fd, &pkt, 1024, 0, (SA *) am_r, &slen);
    if (len == 0)
      exit(0);
    if (len < 0) {
      fprintf(stderr, "%s: mn_recvfrom: %s (%d)\n", prog_name, strerror(errno), errno);
      exit(1);
    }
    printf("%04x:%02x (%d) (l: %d): ", ntohs(am_r->sam_addr), am_r->sam_type, am_r->sam_type, len);
    for (i = 0; i < len; i++)
      printf("%02x ", pkt[i]);
    putchar('\n');
    fflush(stdout);
  }
}
