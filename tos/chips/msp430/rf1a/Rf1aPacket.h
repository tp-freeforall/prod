/*
 * Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
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
 */

/** Define the structures for packets transported using the RF1A radio.
 *
 * All RF1A packets fundamentally use the frame layout described in
 * IEEE Std 802.15.4-2006.  At the moment, we assume 16-bit short
 * address values, and PAN ID compression.
 *
 * TinyOS ActiveMessage packets insert a Not-A-LoWPAN header after the
 * MAC header.  Contrary to the practices recommended in TEP111, this
 * and any other link-layer headers and footers are placed within the
 * message_t data section, since the infrastructure cannot assume that
 * any other headers are present and therefore cannot reserve space
 * for them in the message_t header section.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

#ifndef _Rf1aPacket_H_
#define _Rf1aPacket_H_

#include "Ieee154.h"
#include "Ieee154PacketLayer.h"

enum {
  /** NALP code for ActiveMessage type field */
  LOWPAN_NALP_TINYOS = 0x3f
};

/** Base header is the stock IEEE 802.15.4 MAC header (MHR) */
typedef ieee154_simple_header_t rf1a_ieee154_t;

/** ActiveMessage packets add a NALP header */
typedef nx_struct rf1a_nalp_am_t {
  nxle_uint8_t nalp_tinyos;
  nxle_uint8_t am_type;
} rf1a_nalp_am_t;

/** Metadata common to all packet types */
typedef nx_struct rf1a_metadata_t {
  /** Length of packet payload, including all payload-stored layer
   * headers/footers */
  nxle_uint16_t payload_length;
  /** Raw RSSI value from radio APPEND_STATUS */
  nxle_uint8_t rssi;
  /** Raw LQI+CRC value from radio APPEND_STATUS */
  nxle_uint8_t lqi;
} rf1a_metadata_t;

#ifndef TOSH_DATA_LENGTH
/** Although the RF1A radio stack can accommodate a physical packet up
 * to 255 bytes, to reduce overhead we default to a physical frame
 * limit of 127 bytes, less the size of the fixed header.  Beware that
 * rf1a_nalp_am_t headers cut into this payload space. */
#define TOSH_DATA_LENGTH (127 - sizeof(rf1a_ieee154_t))
#endif // TOSH_DATA_LENGTH

#endif _Rf1aPacket_H_
