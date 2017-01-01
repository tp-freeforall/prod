/*
 * Copyright 2011, Eric B. Decker
 * All rights reserved
 *
 * This work is heavily based on the uncopyrighted work done by
 * W. Richard Stevens and later updated by Bill Fenner and Andrew Rudoff,
 * Unix Network Programming, Volume 1, Third Edition.  Source originally
 * taken from http://unpbook.com/src.html, http://unpbook.com/unpv13e.tar.gz.
 * Source heavily modifed for modern Ubuntu Linux system and only
 * pieces needed copied.
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
#include <sys/types.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>
#include <stdio.h>
#include <string.h>
#include <sys/un.h>

#include "netlib.h"

char *
sock_ntop(const struct sockaddr *sa, socklen_t salen) {
  char        portstr[8];
  static char str[128];		/* Unix domain is largest */

  switch (sa->sa_family) {
    case AF_INET: {
      struct sockaddr_in	*sin = (struct sockaddr_in *) sa;

      if (inet_ntop(AF_INET, &sin->sin_addr, str, sizeof(str)) == NULL)
	return(NULL);
      if (ntohs(sin->sin_port) != 0) {
	snprintf(portstr, sizeof(portstr), ":%d", ntohs(sin->sin_port));
	strcat(str, portstr);
      }
      return(str);
    }

    case AF_INET6: {
      struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *) sa;

      str[0] = '[';
      if (inet_ntop(AF_INET6, &sin6->sin6_addr, str + 1, sizeof(str) - 1) == NULL)
	return(NULL);
      if (ntohs(sin6->sin6_port) != 0) {
	snprintf(portstr, sizeof(portstr), "]:%d", ntohs(sin6->sin6_port));
	strcat(str, portstr);
	return(str);
      }
      return (str + 1);
    }

    case AF_UNIX: {
      struct sockaddr_un *unp = (struct sockaddr_un *) sa;

      /* OK to have no pathname bound to the socket: happens on
	 every connect() unless client calls bind() first. */
      if (unp->sun_path[0] == 0)
	strcpy(str, "(no pathname bound)");
      else
	snprintf(str, sizeof(str), "%s", unp->sun_path);
      return(str);
    }

    default:
      snprintf(str, sizeof(str), "sock_ntop: unknown AF_xxx: %d, len %d",
	       sa->sa_family, salen);
      return(str);
  }
  return (NULL);
}

char *
Sock_ntop(const struct sockaddr *sa, socklen_t salen) {
  char	*ptr;

  if ( (ptr = sock_ntop(sa, salen)) == NULL)
    err_sys("sock_ntop error");	/* inet_ntop() sets errno */
  return(ptr);
}
