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

#ifndef __AM_H__
#define __AM_H__

#include <stdint.h>

#define AM_ENCAP_BASIC	0x00
#define AM_ENCAP_LEN16	0x80

#define AM_ADDR_BCAST   0xffff
#define AM_ADDR_ANY     0x0000

#define AM_GRP_ANY      0x00

#define AM_TYPE_ANY	0x00


#define AM_HDR_LEN      8

typedef struct __attribute__((__packed__)) {
  uint8_t  am_encap;
  uint16_t am_dest;			/* network order */
  uint16_t am_src;			/* network order */
  uint8_t  am_len;
  uint8_t  am_grp;
  uint8_t  am_type;
  uint8_t  am_data[0];
} am_hdr_t;


typedef struct __attribute__((__packed__)) {
  uint8_t  am_encap;
  uint16_t am_dest;			/* network order */
  uint16_t am_src;			/* network order */
  uint16_t am_len;			/* network order */
  uint8_t  am_type;
  uint8_t  am_data[0];
} am_len16_hdr_t;


#endif		/* __AM_H__ */
