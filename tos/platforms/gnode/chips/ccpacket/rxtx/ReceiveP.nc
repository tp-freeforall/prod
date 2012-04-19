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
 * Provides the basic TinyOS Receive interface on top of the HAL interface and
 * timestamps received packets.
 */
module ReceiveP {
	provides {
		interface Receive;
	}

	uses {
		interface HalChipconControl;
		interface Packet;
		interface ChipconPacket;
		interface PacketTimeStamp<T32khz, uint32_t>;
	}
}

implementation {
	
	message_t rxBuffer;
	message_t* message = &rxBuffer;
	
	event void HalChipconControl.rxWaiting(uint32_t timestamp) {
		uint8_t* buffer = (uint8_t*) call ChipconPacket.getHeader(message);
		chipcon_metadata_t* metadata = call ChipconPacket.getMetadata(message);
		uint8_t length;
		
		// read the packet from the FIFO into our buffer, which will return the radio to receive mode
		error_t error = call HalChipconControl.read(buffer);
		if (error == SUCCESS) {
			// two status bytes are appended by the radio chip, move them to the metadata
			// move the last one first, because moving the first might overwrite the second
			// (for a packet larger than TOSH_DATA_LENGTH - 1)
			length = call ChipconPacket.getPacketLength(message);
			metadata->crcAndLqi = buffer[length + 1];
			metadata->rssi = buffer[length];
			call PacketTimeStamp.set(message, timestamp);
			
			dbg("HALRadio", "%s N%u: %s: INFO packet of length %u received with rssi %u and lqi %x\n", sim_time_string(), TOS_NODE_ID, __FUNCTION__, length, metadata->rssi, metadata->crcAndLqi);
			// returned pointer must not be NULL
			message = signal Receive.receive(message, message->data, call Packet.payloadLength(message));
			assert(message != NULL, ASSERT_CC_RXTX_NULL_POINTER);
			
			// The problem with buffer swapping is that everyone has to get it right.
			// By zeroing our buffer, it should be obvious when someone kept a pointer to it,
			// because it will no longer have valid-looking content. 
			memset(message, 0, sizeof(message_t));
		} else {
			// the invalid buffer contents have been flushed and the radio is back in receive mode
		}
	}

	event void HalChipconControl.txStart(uint32_t timestamp) {}
	event void HalChipconControl.txDone(uint32_t timestamp, error_t error) {}
	
	default event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		return msg;
	}
}
