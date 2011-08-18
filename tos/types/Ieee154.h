/*
 * Copyright (c) 2011 Eric B. Decker
 * Copyright (c) 2008-2010 The Regents of the University  of California.
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
 * - Neither the name of the copyright holders nor the names of
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
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

#ifndef __IEEE154_H__
#define __IEEE154_H__

#include "IeeeEui64.h"

#define IEEE154_SEND_CLIENT "IEEE154_SEND_CLIENT"

typedef uint16_t       ieee154_panid_t;
typedef uint16_t       ieee154_saddr_t;
typedef ieee_eui64_t   ieee154_laddr_t;

typedef struct {
  uint8_t ieee_mode:2;
  union {
    ieee154_saddr_t saddr;
    ieee154_laddr_t laddr;
  } ieee_addr;
} ieee154_addr_t;

#define i_saddr ieee_addr.saddr
#define i_laddr ieee_addr.laddr

#ifdef notdef
/*
 * The intent was to consolidate all ieee154 packet definitions
 * in this file.  However a couple of things got in the way.
 *
 * 1) when compiling with blip, for some reason the compile blows
 *    up on the nx_struct ieee154_simple_header_t definition below.
 *    Did look at the resultant C code generated and wasn't able to
 *    figure it out.
 *
 * 2) Miklos is starting a new addressing mechanism for both 16 and
 *    64 bit ieee154 addresses using accessors and packer routines.
 *    That renders this whole thing moot so why bother changing code
 *    to consolidate.
 */
typedef nx_struct ieee154_simple_header_t {
  nxle_uint16_t fcf;
  nxle_uint8_t  dsn;
  nxle_uint16_t destpan;
  nxle_uint16_t dest;
  nxle_uint16_t src;
} ieee154_simple_header_t;

typedef nx_struct ieee154_fcf_t {
  nxle_uint16_t frame_type: 3;
  nxle_uint16_t security_enabled: 1;
  nxle_uint16_t frame_pending: 1;
  nxle_uint16_t ack_request: 1;
  nxle_uint16_t pan_id_compression: 1;
  nxle_uint16_t _reserved: 3;
  nxle_uint16_t dest_addr_mode: 2;
  nxle_uint16_t frame_version: 2;
  nxle_uint16_t src_addr_mode: 2;
} ieee154_fcf_t;
#endif

enum {
  IEEE154_BROADCAST_ADDR = 0xffff,
  IEEE154_BROADCAST_PAN  = 0xffff,
  IEEE154_LINK_MTU       = 127,
};

struct ieee154_frame_addr {
  ieee154_addr_t  ieee_src;
  ieee154_addr_t  ieee_dst;
  ieee154_panid_t ieee_dstpan;
};

enum {
  IEEE154_MIN_HDR_SZ = 6,
};

#ifdef notdef

// deprecated   (does anyone use these?)

struct ieee154_header_base {
  uint8_t length;
  uint16_t fcf;
  uint8_t dsn;
  uint16_t destpan;
} __attribute__((packed));
#endif	/* notdef */

enum ieee154_fcf_enums {
  IEEE154_FCF_FRAME_TYPE = 0,
  IEEE154_FCF_SECURITY_ENABLED = 3,
  IEEE154_FCF_FRAME_PENDING = 4,
  IEEE154_FCF_ACK_REQ = 5,
  IEEE154_FCF_INTRAPAN = 6,
  IEEE154_FCF_DEST_ADDR_MODE = 10,
  IEEE154_FCF_SRC_ADDR_MODE = 14,
};

enum ieee154_fcf_type_enums {
  IEEE154_TYPE_BEACON = 0,
  IEEE154_TYPE_DATA = 1,
  IEEE154_TYPE_ACK = 2,
  IEEE154_TYPE_MAC_CMD = 3,
  IEEE154_TYPE_MASK = 7,
};

enum ieee154_fcf_addr_mode_enums {
  IEEE154_ADDR_NONE = 0,
  IEEE154_ADDR_SHORT = 2,
  IEEE154_ADDR_EXT = 3,
  IEEE154_ADDR_MASK = 3,
};

#ifndef DEFINED_TOS_IEEE154_PAN_ID
// NB: Matches default ActiveMessage group
#define DEFINED_TOS_IEEE154_PAN_ID 22
#endif // DEFINED_TOS_IEEE154_PAN_ID

#ifndef DEFINED_TOS_IEEE154_SHORT_ADDRESS
// NB: Matches default ActiveMessage address
#define DEFINED_TOS_IEEE154_SHORT_ADDRESS 1
#endif // DEFINED_TOS_IEEE154_SHORT_ADDRESS

enum {
  TOS_IEEE154_SHORT_ADDRESS = DEFINED_TOS_IEEE154_SHORT_ADDRESS,
  TOS_IEEE154_PAN_ID = DEFINED_TOS_IEEE154_PAN_ID,
};

#endif	/* __IEEE154_H__ */
