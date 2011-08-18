/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 */

#ifndef __IEEE154PACKETLAYER_H__
#define __IEEE154PACKETLAYER_H__

#include <Ieee154.h>

/*
 * 154 packet format structs should all move to Ieee154.h
 */

typedef nx_struct ieee154_header_t
{
	nxle_uint16_t fcf;
	nxle_uint8_t dsn;
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

#endif//__IEEE154PACKETLAYER_H__
