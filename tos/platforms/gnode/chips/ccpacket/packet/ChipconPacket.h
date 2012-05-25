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

#ifndef CHIPCON_PACKET_H
#define CHIPCON_PACKET_H

#include "AM.h"

enum Flags {
	FLAG_ACK_REQUEST	= 1 << 0,		// if set, sender has requested acknowledgement of this message
	FLAG_ACK_REPLY 		= 1 << 1,		// if set, this is an acknowledgement of another message
};

#define TIMESTAMP_INVALID 0x80000000UL

/**
 * Packet header.
 */
typedef nx_struct chipcon_header_t {
	nx_uint8_t length;	// packet length, including header, excluding the length byte
	nx_am_addr_t dest;	// destination address
	nx_am_addr_t src;	// source address
	nx_uint8_t flags;		// option bits, for things like acknowledgements
	nx_am_id_t type;		// AM type
} chipcon_header_t;

/**
 * Packet footer.
 */
typedef nx_struct chipcon_footer_t {
} chipcon_footer_t;

/**
 * Metadata, contains extra information about the message
 * that will not be transmitted
 */
typedef nx_struct chipcon_metadata_t {
	nx_uint8_t rssi;
	nx_uint8_t crcAndLqi;
	nx_uint8_t ack; // before sending, tracks if acknowledgement was changed from the default. After sending, this indicates if the packet was acknowledged
	nx_uint16_t rxInterval;	// LPL sleep interval of receiver
	nx_uint32_t timestamp;	// transmission or reception timestamp

#ifdef PACKET_LINK
	nx_uint16_t maxRetries;
	nx_uint16_t retryDelay;
#endif

} chipcon_metadata_t;

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 28U
#endif

// maximum packet length (including the length byte and excluding the appended status bytes)
#define MAX_PACKET_LENGTH ((uint8_t) (sizeof(chipcon_header_t) + TOSH_DATA_LENGTH + sizeof(chipcon_footer_t)))

#endif
