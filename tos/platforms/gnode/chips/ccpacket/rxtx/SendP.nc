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

#include "Assert.h"
#include "LowPowerListening.h"

/**
 * Provides the basic TinyOS Send interface on top of the Chipcon HAL layer.
 * It expects the radio to appear to be always on, and in RX mode unless transmitting.
 * Supports arbitrary length preambles for LPL and backs off until the channel is clear.
 * Supports special handling of acknowledgement messages.
 * Supports packet timestamping.
 */
module SendP {
	provides {
		interface StdControl;
		interface Send;
		interface SendNotify;
	}
	
	uses {
		interface HalChipconControl;
		interface ChipconPacket;
		interface Random;
		interface Timer<TMilli> as BackoffTimer;
		interface Timer<TMilli> as PreambleTimer;
		interface PacketTimeStamp<T32khz, uint32_t>;
	}
}

implementation {
	
	#define JIFFIES_PER_MILLI 32
	#define MAX_PACKET_BITS ((PREAMBLE_BYTES + SYNC_BYTES + MAX_PACKET_LENGTH) * 8UL)
	#define MAX_PACKET_DURATION ((MAX_PACKET_BITS * 1024 + 512)/BAUD_RATE)	// add 512 (half a bit time) for rounding
	
	enum Backoff {
		CCA_BACKOFF = CCA_SETTLING_TIME,		// minimum backoff time; covers the time needed for CCA to settle after turning the radio on 
		END_OF_PACKET_BACKOFF = MAX_PACKET_DURATION,	// time to extend the backoff when we hear the end of a packet, to not conflict with a reply packet
		INITIAL_RANDOM_BACKOFF = 4,		// initial upper bound on the random part of the backoff time
		MAX_RANDOM_BACKOFF = 16,		// maximum upper bound on the random part of the backoff time
	};
	
	message_t* message;
	bool busy;
	uint16_t backoffLimit;							// backoff time upper bound
	
	// difference between calculated and actual packet duration 
	int16_t packetDurationAdjustment;
	
	/**
	 * Backoff for a fixed amount of time plus a random amount,
	 * which increases exponentially up to backoffLimit.
	 */
	void backoff(uint16_t fixed) {
		uint16_t delay = fixed + (call Random.rand16() % backoffLimit);
		call BackoffTimer.startOneShot(delay);
		
		// exponentially increase the backoff range, up to MAX_BACKOFF
		backoffLimit *= 2;
		if (backoffLimit > MAX_RANDOM_BACKOFF) backoffLimit =  MAX_RANDOM_BACKOFF;
	}
	
	/**
	 * Load packet into the TX FIFO.
	 */
	void writeData() {
		uint8_t* data = (uint8_t*) call ChipconPacket.getHeader(message);
		uint8_t length = call ChipconPacket.getPacketLength(message);
		call HalChipconControl.write(data, length);
	}
	
	void attemptTx() {
		error_t error;

#ifndef CHIPCON_ALLOW_GLOBAL_BROADCAST
		// TODO: find cause of these packets
		// check the address right before we send
		assert((call ChipconPacket.getHeader(message))->dest != AM_BROADCAST_ADDR, ASSERT_CC_RXTX_BROADCAST);
#endif

		error = call HalChipconControl.tx();
		if (error == SUCCESS) {
			uint16_t interval = (call ChipconPacket.getMetadata(message))->rxInterval;
			if (interval == 0) {
				// receiver always on, send immediately
				writeData();
			} else {
				// transmit preamble long enough to match the receiver's sleep interval
				call PreambleTimer.startOneShot(interval + LPL_PREAMBLE_OVERLAP);
				
				// reset the interval field
				(call ChipconPacket.getMetadata(message))->rxInterval = 0;
			}
		} else if (error == ERETRY || error == FAIL || error == EBUSY) {
			backoff(CCA_BACKOFF);
		} else if (error == EOFF) {
			dbg("SendP", "%s N%u: %s: ERROR SendP TX with radio off\n", sim_time_string(), TOS_NODE_ID, __FUNCTION__);
			signal HalChipconControl.txDone(0, EOFF);
		}  else {
			assertSuccess(error, ASSERT_CANT_HAPPEN);
		}
	}
	
	/**
	 * Ack packets are sent without backoff
	 * and default preamble length.
	 */ 
	error_t sendAck() {
		error_t error;
		
		// we may have to wait for calibration to finish
		// this is rare and doesn't take long
		do {
			error = call HalChipconControl.tx();
		} while (error == ERETRY);
		
		if (error == SUCCESS) {
			writeData();
		}
		
		// both EBUSY and FAIL indicate the packet was not sent,
		// since we don't back off and retry
		if (error == FAIL || error == EBUSY) {
			return FAIL;
		}
		
		// report other errors unchanged
		return error;
	}
	
	event void BackoffTimer.fired() {
		// try again
		attemptTx();
	}
	
	event void PreambleTimer.fired() {
		// done sending preamble
		writeData();
	}
	
	/**
	 * An ack message is indicated by the FLAG_ACK_REPLY flag in the header.
	 */
	bool isAck(message_t* msg) {
		chipcon_header_t* header = call ChipconPacket.getHeader(msg);
		return header->flags & FLAG_ACK_REPLY;
	}

	command error_t Send.send(message_t* msg, uint8_t len) {
		error_t error;

		if (busy) return EBUSY;
		if (len > call Send.maxPayloadLength()) return ESIZE;
		
		message = msg;
		call ChipconPacket.setPayloadLength(message, len);
		
		if (isAck(msg)) {
			// special handling of acknowledgements, which are sent without backoff/CCA, but may fail
			error = sendAck();
		} else {
			// regular message
			backoffLimit = INITIAL_RANDOM_BACKOFF;
			attemptTx();
			
			// will always be sent, eventually
			error = SUCCESS;
		}
		
		if (error == SUCCESS) {
			busy = TRUE;
		}
		
		return error;
	}
	
	event void HalChipconControl.txStart(uint32_t timestamp) {
		// Hal gives us a timestamp for the start of the packet,
		// but the receiver timestamps the end of the packet.
		// Assuming we are already in TX mode, writing the data will trigger sending the sync word
		// which means the packet will end (number of bits / baud rate) seconds later.
		// We assume we'll transmit the preamble, the sync word, /length/ data bytes and a CRC.
		// Afterwards, we'll correct the adjustment based on the actual end of packet timestamp.
		uint8_t bytes = PREAMBLE_BYTES + SYNC_BYTES + CRC_BYTES + call ChipconPacket.getPacketLength(message);
		uint16_t bits = bytes * 8;
		uint32_t duration = (bits * 1024UL * JIFFIES_PER_MILLI + 512) / BAUD_RATE + packetDurationAdjustment;
		call PacketTimeStamp.set(message, timestamp + duration);
		signal SendNotify.sending(message);
	}
	
	event void HalChipconControl.txDone(uint32_t timestamp, error_t error) {
		if (error == ERETRY) {
			// FIFO underflow, try again
			attemptTx();
		} else {
			if (error == SUCCESS) {
				// see how much our estimated end time was off from the actual end time and update our adjustment
				uint32_t estimate = call PacketTimeStamp.timestamp(message) - packetDurationAdjustment;
				packetDurationAdjustment = timestamp - estimate;
//				platform_printf("txS: %lu %lu %d %d\n", call PacketTimeStamp.timestamp(message), timestamp,
//					(int16_t) (timestamp - call PacketTimeStamp.timestamp(message)), packetDurationAdjustment);
			}
			
			busy = FALSE;
			signal Send.sendDone(message, error);
		}
	}
	
	/**
	 * We can cancel a message when it's still in backoff.
	 */
	command error_t Send.cancel(message_t* msg) {
		if (msg == message && call BackoffTimer.isRunning()) {
			call BackoffTimer.stop();
			busy = FALSE;
			signal Send.sendDone(message, ECANCEL);
			return SUCCESS;
		} else {
			return FAIL;
		}
	}
	
	command uint8_t Send.maxPayloadLength() {
		// full payload length available
		return TOSH_DATA_LENGTH;
	}
	
	command void* Send.getPayload(message_t* msg, uint8_t len) {
		if(len > call Send.maxPayloadLength()) {
			return NULL;
		} else {
			return (void* COUNT_NOK(len))msg->data;
		}
	}
	
	/**
	 * Extend the backoff when we see the end of a packet
	 * so we don't conflict with a possible reply packet following it.
	 */
	event void HalChipconControl.rxWaiting(uint32_t timestamp) {
		if (call BackoffTimer.isRunning()) {
			backoff(END_OF_PACKET_BACKOFF);
		}
	}
	
	command error_t StdControl.start() {
		return SUCCESS;
	}
	
	command error_t StdControl.stop() {
		if (busy && call BackoffTimer.isRunning()) {
			// stop waiting and signal sendDone(EOFF) immediately
			call BackoffTimer.stop();
			signal HalChipconControl.txDone(0, EOFF);
		}
		
		return SUCCESS;
	}
	
	default event void SendNotify.sending(message_t* msg) {}
}
