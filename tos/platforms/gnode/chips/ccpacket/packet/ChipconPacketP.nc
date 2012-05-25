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

#include "message.h"

module ChipconPacketP {
	provides {
		interface ChipconPacket;
		interface Packet;
		interface AMPacket;
		interface PacketAcknowledgements;
		interface PacketTimeStamp<T32khz, uint32_t>;
	}
	
	uses {
		interface ActiveMessageAddress;
		interface NetMask;
	}
}

implementation {
	
	/**
	 * Return the broadcast address for our AM group, i.e. the address with all 1's for the node ID bits.
	 * Hence, it's our group OR'd with the inverted netmask.
	 */
	am_addr_t getLocalBroadcastAddress() {
		return call ActiveMessageAddress.amGroup() | ~(call NetMask.netMask());
	}
	
	async command chipcon_header_t* ChipconPacket.getHeader(message_t* msg) {
		return (chipcon_header_t*) (msg->data - sizeof(chipcon_header_t));
	}
	
	async command chipcon_footer_t* ChipconPacket.getFooter(message_t* msg) {
		return (chipcon_footer_t*) (msg->footer);
	}
	
	async command chipcon_metadata_t* ChipconPacket.getMetadata(message_t* msg) {
		return (chipcon_metadata_t*) (msg->metadata);
	}
	
	async command uint8_t ChipconPacket.getPacketLength(message_t* msg) {
		// the length byte in the header does not include itself, so add one
		return (call ChipconPacket.getHeader(msg))->length + 1;
	}

	async command uint8_t ChipconPacket.getPayloadLength(message_t* msg) {
		// payload length is packet length minus the header and footer
		return call ChipconPacket.getPacketLength(msg) - (sizeof(chipcon_header_t) + sizeof(chipcon_footer_t));
	}
	
	async command void ChipconPacket.setPayloadLength(message_t* msg, uint8_t len) {
		(call ChipconPacket.getHeader(msg))->length = sizeof(chipcon_header_t) + len + sizeof(chipcon_footer_t) - 1;
	}
	
	command void Packet.clear(message_t* msg) {
		// according to TEP116, this should only clear the headers/footers/metadata, not payload
		memset(call ChipconPacket.getHeader(msg), 0, sizeof(chipcon_header_t));
		memset(call ChipconPacket.getFooter(msg), 0, sizeof(chipcon_footer_t));
		memset(call ChipconPacket.getMetadata(msg), 0, sizeof(chipcon_metadata_t));
	}

	command uint8_t Packet.payloadLength(message_t* msg) {
		return call ChipconPacket.getPayloadLength(msg);
	}

	command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
		call ChipconPacket.setPayloadLength(msg, len);
	}

	command uint8_t Packet.maxPayloadLength() {
		return TOSH_DATA_LENGTH;
	}

	command void* Packet.getPayload(message_t* msg, uint8_t len) {
		if(len > call Packet.maxPayloadLength()) {
			return NULL;
		} else {
			return (void* COUNT_NOK(len))msg->data;
		}
	}
	
	command am_addr_t AMPacket.address() {
		return call ActiveMessageAddress.amAddress();
	}
	
	command am_group_t AMPacket.localGroup() {
		return call ActiveMessageAddress.amGroup();
	}
	
	command am_addr_t AMPacket.destination(message_t* amsg) {
		chipcon_header_t* header = call ChipconPacket.getHeader(amsg);
		// convert a "physical" broadcast address to a "logical" broadcast address
		if (header->dest == getLocalBroadcastAddress()) {
			return AM_BROADCAST_ADDR;
		} else {
			return header->dest;
		}
	}

	command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
		chipcon_header_t* header = call ChipconPacket.getHeader(amsg);
		// convert a "logical" broadcast address to a "physical" broadcast address
		if (addr == AM_BROADCAST_ADDR) {
			atomic header->dest = getLocalBroadcastAddress();
		} else {
			header->dest = addr;
		}
	}
	
	command am_addr_t AMPacket.source(message_t* amsg) {
		chipcon_header_t* header = call ChipconPacket.getHeader(amsg);
		return header->src;
	}
	
	command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
		chipcon_header_t* header = call ChipconPacket.getHeader(amsg);
		header->src = addr;
	}

	command bool AMPacket.isForMe(message_t* amsg) {
		// AMPacket.destination()/setDestination() transparently convert between the local broadcast address
		// and AM_BROADCAST_ADDR (255.255.255.255).
		// Applications are not expected to send or receive on the global broadcast address, so we require
		// the AM group to match. That way, a packet actually sent to the global broadcast address can still be
		// received by snooping, but not by accident.
		
		return call AMPacket.group(amsg) == call AMPacket.localGroup() &&
				(call AMPacket.destination(amsg) == call AMPacket.address() || call AMPacket.destination(amsg) == AM_BROADCAST_ADDR);
	}

	command am_id_t AMPacket.type(message_t* amsg) {
		chipcon_header_t* header = call ChipconPacket.getHeader(amsg);
		return header->type;
	}

	command void AMPacket.setType(message_t* amsg, am_id_t type) {
		chipcon_header_t* header = call ChipconPacket.getHeader(amsg);
		header->type = type;
	}

	command am_group_t AMPacket.group(message_t* amsg) {
		chipcon_header_t* header = call ChipconPacket.getHeader(amsg);
		return header->dest & call NetMask.netMask();
	}

	/**
	 * Does nothing, because the group information is contained in the source
	 * and destination addresses.
	 */
	command void AMPacket.setGroup(message_t* amsg, am_group_t grp) {}

	
	/**
	 * Set or clear the ack bit in the header and set the ack flag in the metadata.
	 */
	void setAck(message_t* msg, bool ack) {
		chipcon_header_t* header = call ChipconPacket.getHeader(msg);
		chipcon_metadata_t* metadata = call ChipconPacket.getMetadata(msg);
		if (ack) {
			// set the ack request bit
			header->flags |= FLAG_ACK_REQUEST;
		} else {
			// clear the ack request bit
			header->flags &= ~FLAG_ACK_REQUEST;
		}
		
		// set the ack field in the metadata to indicate the default was overridden
		metadata->ack = TRUE;
	}
	
	async command error_t PacketAcknowledgements.requestAck(message_t* msg) {
		setAck(msg, TRUE);
		return SUCCESS;
	}
	
	async command error_t PacketAcknowledgements.noAck(message_t* msg) {
		setAck(msg, FALSE);
		return SUCCESS;
	}
	
	async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
		chipcon_metadata_t* metadata = call ChipconPacket.getMetadata(msg);
		return metadata->ack;
	}
	
	async command bool PacketTimeStamp.isValid(message_t* msg) {
		return call PacketTimeStamp.timestamp(msg) != TIMESTAMP_INVALID;
	}
	
	async command uint32_t PacketTimeStamp.timestamp(message_t* msg) {
		chipcon_metadata_t* metadata = call ChipconPacket.getMetadata(msg);
		return metadata->timestamp;
	}
	
	async command void PacketTimeStamp.clear(message_t* msg) {
		chipcon_metadata_t* metadata = call ChipconPacket.getMetadata(msg);
		metadata->timestamp = TIMESTAMP_INVALID;
	}
	
	async command void PacketTimeStamp.set(message_t* msg, uint32_t value) {
		chipcon_metadata_t* metadata = call ChipconPacket.getMetadata(msg);
		metadata->timestamp = value;
	}
	
	async event void ActiveMessageAddress.changed() {}
	
}
