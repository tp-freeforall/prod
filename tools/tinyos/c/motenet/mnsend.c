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
  fprintf(stderr, "usage: %s <host>:<port> <bytes>\n", name);
  fprintf(stderr, "       %s server@<host>:<port> <bytes>\n", name);
  fprintf(stderr, "       %s serial@<serial device>:<baud rate> <bytes>\n", name);
  fprintf(stderr, "\n");
  fprintf(stderr, "    host:   <ipv4> or <ipv6> node or explicit address\n");
  fprintf(stderr, "    server: AM gateway server\n");
  fprintf(stderr, "    serial: AM serial gateway via serial port\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "    environment var MOTECOM can set the connection\n");
  fprintf(stderr, "    command line overrides MOTECOM\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "    <bytes> specifiy AM packet to send.   Includes AM encapsulation\n");
  fprintf(stderr, "    all fields in hex, multibyte fields in network order\n\n");
  fprintf(stderr, "      00 dddd ssss ll gg tt <data>\n");
  fprintf(stderr, "	 dddd = dest, ssss = src, ll = len, gg = group, tt = type\n");
  fprintf(stderr, "  ie. mnsend server@localhost:9001 00 0004 0001 03 00 a0 03 00 01\n");
  exit(2);
}


motecom_conn_t mcs_conn;

int
main(int argc, char **argv) {
  char *prog_name, *p;
  int fd, err;
  int arg_index, val;
  char    buff[256];
  struct sockaddr_am *am_l,         *am_r;
  struct sockaddr_am  am_local_addr, am_remote_addr;
  uint8_t pkt[1024], *b;
  socklen_t slen;
  am_hdr_t *amh;

  uint8_t  encap;
  uint16_t dest, src;
  uint8_t  len;
  uint8_t  grp;
  uint8_t  type;

  prog_name = basename(argv[0]);

  /* must specifiy enough for the header at a minimum */
  if (argc < 7)
    usage(prog_name);

  /* see if a connection string was specified, presence of ':' indicates */
  p = strchr(argv[1], ':');
  if (p) {
    p = argv[1];
    arg_index = 2;
  } else {
    p = NULL;
    arg_index = 1;
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

  memset(pkt, 0, sizeof(pkt));

  amh = (am_hdr_t *) &pkt[0];
  encap = strtol(argv[arg_index++], &p, 16);
  dest  = strtol(argv[arg_index++], &p, 16);
  src   = strtol(argv[arg_index++], &p, 16);
  len   = strtol(argv[arg_index++], &p, 16);
  grp   = strtol(argv[arg_index++], &p, 16);
  type  = strtol(argv[arg_index++], &p, 16);

  amh->am_encap = encap;
  amh->am_dest  = htons(dest);
  amh->am_src   = htons(src);
  amh->am_len   = len;
  amh->am_grp   = grp;
  amh->am_type  = type;

  am_l = &am_local_addr;
  am_l->sam_family = AF_AM;
  am_l->sam_addr   = htons(src);
  am_l->sam_grp    = AM_GRP_ANY;
  am_l->sam_type   = type;

  am_r = &am_remote_addr;
  am_r->sam_family = AF_AM;
  am_r->sam_addr   = htons(dest);
  am_r->sam_grp    = AM_GRP_ANY;
  am_r->sam_type   = type;

  b = &pkt[AM_HDR_LEN];

  while (arg_index < argc) {
    val = strtol(argv[arg_index++], NULL, 16);
    *(b++) = val & 0xff;
  }

  len = b - &pkt[0];

  /* use sock_raw because we are sending the AM header too */
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

  slen = sizeof(*am_r);
  val = mn_sendto(fd, &pkt, len, 0, (SA *) am_r, slen);
  if (val < 0) {
    fprintf(stderr, "%s: mn_sendto: %s (%d)\n", prog_name, strerror(errno), errno);
    exit(1);
  }

  /*
   * we turned on debugging so the lower layer will display the packet that
   * was sent.
   */

  exit(0);
}
