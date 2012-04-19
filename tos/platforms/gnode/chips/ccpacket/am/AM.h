/*
 * Copyright (c) 2008-2012, SOWNet Technologies B.V.
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
*/

#ifndef AM_H
#define AM_H

typedef uint8_t am_id_t;
typedef nx_uint8_t nx_am_id_t;

typedef uint32_t am_netmask_t;
typedef uint32_t am_group_t;
typedef uint32_t am_addr_t;

// nx versions are little endian because the radio can only check one byte
// and we want that to be the least significant byte (most likely to differ)
typedef nxle_uint32_t nx_am_netmask_t;
typedef nxle_uint32_t nx_am_group_t;
typedef nxle_uint32_t nx_am_addr_t;

// defaults
#ifndef DEFINED_AM_NETWORK_MASK
#define DEFINED_AM_NETWORK_MASK 0xFFFF0000UL
#endif

#ifndef DEFINED_TOS_AM_GROUP
#define DEFINED_TOS_AM_GROUP 0x00000000UL
#endif

#ifndef DEFINED_TOS_AM_ADDRESS
#define DEFINED_TOS_AM_ADDRESS (DEFINED_TOS_AM_GROUP | 1)
#endif

// all access to these SHOULD go through ActiveMessageAddressC
//#define TOS_AM_ADDRESS DEFINED_TOS_AM_ADDRESS
//#define TOS_AM_GROUP DEFINED_TOS_AM_GROUP
//#define AM_NETWORK_MASK DEFINED_AM_NETWORK_MASK

// this is the "logical" broadcast address, irrespective of radio group
#define AM_BROADCAST_ADDR 0xFFFFFFFFUL

#define UQ_AMQUEUE_SEND "amqueue.send"

// printf formatting
#define DOTTED_QUAD_FORMAT "%lu.%lu.%lu.%lu"
#define DOTTED_QUAD(addr) (addr >> 24) & 0xFF, (addr >> 16) & 0xFF, (addr >> 8) & 0xFF, (addr >> 0) & 0xFF

#endif
