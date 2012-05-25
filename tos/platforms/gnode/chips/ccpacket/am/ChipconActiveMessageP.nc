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

/**
 * The Active Message layer for the Chipcon packet radio.
 */
module ChipconActiveMessageP @safe() {
	provides {
		interface StdControl;
		interface SplitControl;
		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];
	}
	
	uses {
		interface StdControl as SubControl;
		interface Send as SubSend;
		interface Receive as SubReceive;
		interface AMPacket;
		interface PacketMetadata;
		interface Crc;
	}
}

implementation {
	
	bool txBusy;
	uint16_t crc;	// for checking whether what goes in also comes out
	
	task void started() {
		signal SplitControl.startDone(SUCCESS);
	}
	
	task void stopped() {
		signal SplitControl.stopDone(SUCCESS);
	}
	
	command error_t SplitControl.start() {
		error_t error = call SubControl.start();
		dbg("ActiveMessageP", "%s N%u: %s: Started with error %u\n", sim_time_string(), TOS_NODE_ID, __FUNCTION__, error);
		if (error == SUCCESS) post started();
		return error;
	}

	command error_t SplitControl.stop() {
		error_t error = call SubControl.stop();
		dbg("ActiveMessageP", "%s N%u: %s: Stopped with error %u\n", sim_time_string(), TOS_NODE_ID, __FUNCTION__, error);
		if (error == SUCCESS) post stopped();
		return error;
	}

	// While StdControl is convenient, other components may depend on the SplitControl events. 
	// CtpForwardingEngine looks for startDone/stopDone events to know whether the radio is on.
	
	command error_t StdControl.start() {
		error_t error = call SubControl.start();
		dbg("ActiveMessageP", "%s N%u: %s: Started with error %u\n", sim_time_string(), TOS_NODE_ID, __FUNCTION__, error);
		if (error == SUCCESS) signal SplitControl.startDone(SUCCESS);
		return error;
	}

	command error_t StdControl.stop() {
		error_t error = call SubControl.stop();
		dbg("ActiveMessageP", "%s N%u: %s: Stopped with error %u\n", sim_time_string(), TOS_NODE_ID, __FUNCTION__, error);
		if (error == SUCCESS) signal SplitControl.stopDone(SUCCESS);
		return error;
	}
	
#ifdef DEBUG_CHIPCON_AM
	void print(message_t* msg, uint8_t len, char* NTS s, bool rx) {
		uint8_t i;
		uint8_t* payload = (uint8_t*) call SubSend.getPayload(msg, len);
		
		platform_printf("AM: %s: src=" DOTTED_QUAD_FORMAT ", dst=" DOTTED_QUAD_FORMAT ", am=%u, len=%u,",
				s, DOTTED_QUAD(call AMPacket.source(msg)), DOTTED_QUAD(call AMPacket.destination(msg)),
				call AMPacket.type(msg), len);
		
		if (rx) {
			platform_printf(" rssi=%d, lqi=%u,", call PacketMetadata.getRssi(msg), call PacketMetadata.getLqi(msg));
		}
		
		for (i=0; i < len; i++) {
			platform_printf(" %02X", payload[i]);
		}
		
		platform_printf("\n");
	}
#endif
	
	uint16_t crcMessage(message_t* msg) {
#ifdef AM_TIMESYNCMSG
		// time sync messages have their time stamp changed, so only check the header
		uint8_t len = sizeof(message_header_t);
#else
		// metadata is allowed to change, so don't include that in the checksum
		uint8_t len = sizeof(message_header_t) + TOSH_DATA_LENGTH + sizeof(message_footer_t);
#endif
		
		return call Crc.crc16(msg, len);
	}
	
	command error_t AMSend.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len) {
		error_t error;
		if (txBusy) return EBUSY;
		
		call AMPacket.setType(msg, id);
		call AMPacket.setDestination(msg, addr);
		call AMPacket.setSource(msg, call AMPacket.address());
#ifdef DEBUG_CHIPCON_AM
		print(msg, len, "TX", FALSE);
#endif
		dbg("ActiveMessageP", "%s N%u: %s: Calling radio send for msg type %u, length %u, dest %u\n", sim_time_string(), TOS_NODE_ID, __FUNCTION__, id, len, addr);

		error = call SubSend.send(msg, len);
		if (error == SUCCESS) {
			txBusy = TRUE;
			crc = crcMessage(msg);
		}

		dbg("ActiveMessageP", "%s N%u: %s: Radio send %u (msg type %u, length %u, dest %u)\n", sim_time_string(), TOS_NODE_ID, __FUNCTION__, error, id, len, addr);

		return error;
	}

	command error_t AMSend.cancel[am_id_t id](message_t* msg) {
		return call SubSend.cancel(msg);
	}

	command uint8_t AMSend.maxPayloadLength[am_id_t id]() {
		return call SubSend.maxPayloadLength();
	}

	command void* AMSend.getPayload[am_id_t id](message_t* m, uint8_t len) {
		return call SubSend.getPayload(m, len);
	}

	event void SubSend.sendDone(message_t* msg, error_t result) {
		dbg("ActiveMessageP", "%s N%u: %s: Radio sendDone %u (msg type %u, dest %u)\n", sim_time_string(), TOS_NODE_ID, __FUNCTION__, result, call AMPacket.type(msg), call AMPacket.destination(msg));
		
#ifdef DEBUG_CHIPCON_AM
		if (crc != crcMessage(msg)) {
			uint8_t len = sizeof(message_header_t) + TOSH_DATA_LENGTH + sizeof(message_footer_t);
			print(msg, len, "msg", FALSE);
		}
#endif
		
		assertEquals(crc, crcMessage(msg), ASSERT_CC_AM_MODIFIED);
		
		txBusy = FALSE;
		signal AMSend.sendDone[call AMPacket.type(msg)](msg, result);
	}

	event message_t* SubReceive.receive(message_t* msg, void *payload, uint8_t len) {
#ifdef DEBUG_CHIPCON_AM
		print(msg, len, "RX", TRUE);
#endif
		dbg("ActiveMessageP", "%s N%u: %s: Radio received msg from %u type %u, length %u, dest %u\n", sim_time_string(), TOS_NODE_ID, __FUNCTION__, call AMPacket.source(msg), call AMPacket.type(msg), len, call AMPacket.destination(msg));
		if (call AMPacket.isForMe(msg)) {
			return signal Receive.receive[call AMPacket.type(msg)](msg, payload, len);
		} else {
			return signal Snoop.receive[call AMPacket.type(msg)](msg, payload, len);
		}
	}
	
	default event void SplitControl.startDone(error_t error) {}
	default event void SplitControl.stopDone(error_t error) {}

	default event message_t* Receive.receive[am_id_t id](message_t* msg, void *payload, uint8_t len) {
		return msg;
	}

	default event message_t* Snoop.receive[am_id_t id](message_t* msg, void *payload, uint8_t len) {
		return msg;
	}

	default event void AMSend.sendDone[am_id_t id](message_t* msg, error_t err) {}
	
}
