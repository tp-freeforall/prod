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
 * Provides synchronous acknowledgements.
 * 
 * @author Michiel Konstapel
 */
module AckP {
	provides {
		interface StdControl;
		interface Send;
		interface Receive;
	}
	
	uses {
		interface StdControl as SubControl;
		interface Send as SubSend;
		interface Receive as SubReceive;
		interface Packet;
		interface ChipconPacket;
		interface AMPacket;
		interface PacketAcknowledgements;
		interface Timer<TMilli> as AckTimer;
	}
}

implementation {
	
	#include "Ack.h"
	#include "ChipconRegisterValues.h"

	// total length of an ack packet
	#define ACK_BYTES (PREAMBLE_BYTES + SYNC_BYTES + sizeof(chipcon_header_t))
	
	// time it takes to send an ack packet - 4 ms at 38400 bps
	#define ACK_TX_TIME ((ACK_BYTES * 8 * 1024UL) / BAUD_RATE)
	
	// Time to wait for an acknowledgement, in addition to transmission time.
	// Test results so far:
	// - just send/receive: 1 ms required
	// - with some printfs involved: 3 ms
	// - when running CTP: 4 ms
	// Applications may introduce more delays, so I'm setting this conservatively for now.
	#ifndef ACK_EXTRA_TIME
	#define ACK_EXTRA_TIME 20
	#endif
	
	#define ACK_WAIT_TIME (ACK_TX_TIME + ACK_EXTRA_TIME)
	
	message_t rxBuffer;		// for buffer swapping
	message_t* buffer = &rxBuffer;	// current receive buffer
	
	// ack messages are just headers, but packet timestamping writes into the metadata fields,
	// so we do need a full message_t
	message_t ackBuffer;
	message_t* ackMessage = &ackBuffer;
	message_t* txMessage;	// the message being sent, either pending or awaiting an acknowledgement
	message_t* rxMessage;	// the message being received, held while we're sending its acknowledgement
	
	bool sending;				// between send() and sendDone()
	bool subSending;			// packet handed off to lower layer
	bool acking;					// sending an ack
	
	command error_t StdControl.start() {
		return call SubControl.start();
	}
	
	command error_t StdControl.stop() {
		// LowPowerListening might try to turn us off when it sees no radio activity,
		// but we might be busy sending an ack.
		if (acking) {
			platform_printf("Ack: stop: EBUSY\n");
			return EBUSY;
		}
		
		return call SubControl.stop();
	}
	
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
	
	/**
	 * @return TRUE if this message should be acked: not a broadcast and the ack request flag is set.
	 */
	bool needsAck(message_t* msg) {
		chipcon_header_t* header = call ChipconPacket.getHeader(msg);
		return call AMPacket.destination(msg) != AM_BROADCAST_ADDR &&  (header->flags & FLAG_ACK_REQUEST);
	}

	/**
	 * Acks are sent with the FLAG_ACK_REPLY bit set.
	 */
	bool isAck(message_t* msg) {
		chipcon_header_t* header = call ChipconPacket.getHeader(msg);
		return header->flags & FLAG_ACK_REPLY;
	}
	
	/**
	 * Check whether the source and destination fields match our sent packet.
	 */
	bool matchAck(message_t* msg) {
		chipcon_header_t* ackHeader = call ChipconPacket.getHeader(msg);
		chipcon_header_t* txHeader = call ChipconPacket.getHeader(txMessage);
		assert(ackHeader->flags & FLAG_ACK_REPLY, ASSERT_CC_ACK_PACKET);
		return
			ackHeader->dest == txHeader->src &&
			ackHeader->src == txHeader->dest;
	}
	
	/**
	 * Create and send an acknowledgement for this message.
	 */
	error_t sendAck(message_t* msg) {
		error_t error;
		
		// create ack packet by copying the received header, easy way to obtain correct AM group
		// swap source/dest fields, clear the ack request flag, and set the flag indicating this is an ack
		chipcon_header_t* rxHeader = call ChipconPacket.getHeader(msg);
		chipcon_header_t* ackHeader = call ChipconPacket.getHeader(ackMessage);
		*ackHeader = *rxHeader;
		ackHeader->src = rxHeader->dest;
		ackHeader->dest = rxHeader->src;
		ackHeader->flags &= ~FLAG_ACK_REQUEST;
		ackHeader->flags |= FLAG_ACK_REPLY;
		
		// lower layer may be busy sending a packet if we gave it a message to send
		// while the packet we want to ack was being received
		error = call SubSend.send(ackMessage, 0);
		if (error == SUCCESS) {
			return SUCCESS;
		} else if (error == EBUSY) {
			// try cancelling the packet
			if (call SubSend.cancel(txMessage) == SUCCESS) {
				subSending = FALSE;
				platform_printf("Ack: cancelled data for ack\n");
				
				// data packet cancelled;
				// sending is still TRUE and subSending is now FALSE again, so after sending our ack packet, the data packet will be resent
				// sending the ack may still fail if the radio is busy (because we won't wait/backoff)
				error = call SubSend.send(ackMessage, 0);
				if (error == SUCCESS) {
					platform_printf("Ack: sending ack\n");
				} else {
					// can't send ack, "uncancel" the data packet
					error_t resendError;
					platform_printf("Ack: still couldn't ack: %d\n", error);
					
					// we're not busy so this must succeed
					resendError = call SubSend.send(txMessage, call ChipconPacket.getPayloadLength(txMessage));
					assertSuccess(resendError, ASSERT_CC_ACK_SEND);
					subSending = TRUE;
				}
				
				return error;
			} else {
				// well, tough luck
				platform_printf("Ack: couldn't cancel, no ack\n");
				return FAIL;
			}
		} else {
			platform_printf("Ack: send: %u\n", error);
			return error;
		}
	}
	
	/**
	 * Signal Send.sendDone() and reset the ack flag for the next send operation.
	 */
	void sendDone(error_t error) {
		message_t* tmp;
		assert(txMessage != NULL, ASSERT_CC_ACK_STATE);
		tmp = txMessage;
		txMessage = NULL;
		sending = FALSE;
		signal Send.sendDone(tmp, error);
		(call ChipconPacket.getMetadata(tmp))->ack = FALSE;
	}
	
	event void SubSend.sendDone(message_t* msg, error_t error) {
		if (error == ECANCEL) {
			// we've cancelled a packet to send an ack
			// nothing to do; packet will be resent afterwards
			return;
		}
		
		if (msg == ackMessage) {
			// ack sent, deliver the message we received and see if we have a regular message waiting
			uint8_t payloadLength;
			assert(acking, ASSERT_CC_ACK_STATE);
			acking = FALSE;
			
			// deliver the message and use the returned message_t* as our buffer
			payloadLength = call Packet.payloadLength(rxMessage);
			buffer = signal Receive.receive(rxMessage, call Packet.getPayload(rxMessage, payloadLength), payloadLength);
			
			// we may receive multiple messages, and send multiple acks, while our client message is in backoff
			// so keep track of whether we've already called SubSend.send()
			if (sending && !subSending) {
				error = call SubSend.send(txMessage, call ChipconPacket.getPayloadLength(txMessage));
				assertSuccess(error, ASSERT_CC_ACK_SEND);
				subSending = TRUE;
			}
		} else {
			// we just sent a regular message
			assert(msg == txMessage, ASSERT_CC_ACK_STATE);
			if (error == SUCCESS) {
				// regular packet sent; radio is now in RX mode to receive an acknowledgement
				// expect an acknowledgement if the message was not a broadcast and the ack request flag is set
				if (needsAck(msg)) {
					call AckTimer.startOneShot(ACK_WAIT_TIME);
				} else {
					// not acked, still successful
					(call ChipconPacket.getMetadata(txMessage))->ack = FALSE;
					sendDone(SUCCESS);
				}
			} else {
				// not successfully sent
				platform_printf("Ack: ERROR %d\n", error);
				(call ChipconPacket.getMetadata(txMessage))->ack = FALSE;
				sendDone(error);
			}
		}
	}
	
	command error_t Send.send(message_t* msg, uint8_t len) {
		chipcon_metadata_t* metadata = call ChipconPacket.getMetadata(msg);
		
		if (sending) return EBUSY;
		sending = TRUE;
		subSending = FALSE;
		
		if (!metadata->ack) {
			// acknowledgement not explicitly specified, use the default
			setAck(msg, ACK_DEFAULT);
		}
		
		assert(txMessage == NULL, ASSERT_CC_ACK_STATE);
		txMessage = msg;
		
		if (acking) {
			// we'll send it after the ack, so remember the length
			call ChipconPacket.setPayloadLength(txMessage, len);
			return SUCCESS;
		} else {
			// send rightaway
			// since we're not busy, this mustn't fail
			error_t error = call SubSend.send(msg, len);
			assertSuccess(error, ASSERT_CC_ACK_SEND);
			subSending = TRUE;
			return SUCCESS;
		}
	}
	
	/**
	 * Message received.
	 * If it is an acknowledgement, see if it acknowledges the packet we sent. If so, signal sendDone().
	 * If it is a normal message, see if it requests an ack. If so, send the ack. Else, deliver the message up the stack.
	 */
	event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
		if (isAck(msg)) {
			if (sending && matchAck(msg)) {
				if (call AckTimer.isRunning()) {
					call AckTimer.stop();
					(call ChipconPacket.getMetadata(txMessage))->ack = TRUE;
					sendDone(SUCCESS);
				} else {
					// ignore acks that arrive too late, we already signalled sendDone()
					platform_printf("*** Ack: too late\n");
				}
			}
			
			return msg;
		} else {
			if (needsAck(msg) && call AMPacket.destination(msg) == call AMPacket.address()) {
				if (sendAck(msg) == SUCCESS) {
					// swap buffers: keep the incoming pointer to signal upwards later
					// and return our buffer to the lower layer
					acking = TRUE;
					rxMessage = msg;
					return buffer;
				}
			}

			// ack either failed or wasn't needed; deliver immediately
			return signal Receive.receive(msg, payload, len);
		}
	}
	
	event void AckTimer.fired() {
		// platform_printf("Ack: expired\n");
		// timer expired: acknowledgement expected but not received
		(call ChipconPacket.getMetadata(txMessage))->ack = FALSE;
		sendDone(SUCCESS);
	}
	
	/**
	 * Not supported: we use SubSend.cancel() internally.
	 * Could be made to work by allowing cancellation when acking is FALSE,
	 * or by using a separate flag.
	 */
	command error_t Send.cancel(message_t* msg) {
		return FAIL;
	}
	
	command uint8_t Send.maxPayloadLength() {
		return call SubSend.maxPayloadLength();
	}
	
	command void* Send.getPayload(message_t* msg, uint8_t len) {
		return call SubSend.getPayload(msg, len);
	}

}
