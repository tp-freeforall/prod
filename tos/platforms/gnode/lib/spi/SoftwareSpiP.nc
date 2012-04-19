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
 * Provides a software implementation of the SPI protocol.
 * Also provides a fake Resource implementation, since
 * it is not meant to be shared.
 */
generic module SoftwareSpiP(uint8_t polarity, uint8_t phase) {
	provides {
		interface Init;
		interface SpiByte;
		interface SpiPacket;
		interface Resource;
	}
	
	uses {
		interface GeneralIO as MOSI;
		interface GeneralIO as MISO;
		interface GeneralIO as Clock;
	}
}

implementation {
	
	bool busy = FALSE;
	
	// these are protected by the busy flag
	norace uint8_t* txBuffer;
	norace uint8_t* rxBuffer;
	norace uint16_t length;
	norace uint16_t count;
	
	/**
	 * Initialise I/O pins.
	 */
	void init() {
		call MISO.makeInput();
		call MOSI.makeOutput();
		call Clock.makeOutput();
		if (polarity == 0) {
			call Clock.clr(); // idle low
		} else {
			call Clock.set(); // idle high
		}		
	}
	
	command error_t Init.init() {
		init();
		return SUCCESS;
	}
	
	inline void clockLead() {
		// leading clock edge
		if (polarity == 0) {
			// base value is low, start with rising edge
			call Clock.set();
		} else {
			// base value is high, start with falling edge
			call Clock.clr();
		}
	}
	
	inline void clockTrail() {
		// trailing clock edge
		if (polarity == 0) {
			// falling edge
			call Clock.clr();
		} else {
			// rising edge
			call Clock.set();
		}
	}
	
	inline void write(uint8_t bit) {
		if (bit) call MOSI.set();
		else call MOSI.clr();
	}
	
	inline uint8_t read() {
		return call MISO.get();
	}
	
	/**
	 * Send/receive a single bit.
	 */
	uint8_t sendBit(uint8_t bit) {
		uint8_t rx;
		
		if (phase == 0) {
			// sample on the leading edge, change on the trailing edge
			write(bit);
			clockLead();
			rx = read();
			clockTrail();
		} else {
			// change on the leading edge, sample on the trailing edge
			clockLead();
			write(bit);
			clockTrail();
			rx = read();
		}
		
		return rx;
	}
	
	/**
	 * Synchronous transmit and receive (can be in interrupt context)
	 * @param tx Byte to transmit
	 * @param rx Received byte is stored here.
	 */
	async command uint8_t SpiByte.write(uint8_t tx) {
		uint8_t i;
		uint8_t rx = 0;
		for (i = 0; i < 8; i++) {
			// MSB first, so send top bit and receive bottom bit, then shift left
			rx |= sendBit(tx >> 7);
			
			// don't shift after the last bit
			if (i < 7) {
				tx <<= 1;
				rx <<= 1;
			}
		}
		
		return rx;
	}
	
	/**
	 * Process /length/ bytes, one byte per run.
	 */
	task void send() {
		uint8_t received = call SpiByte.write(txBuffer == NULL ? 0 : txBuffer[count]);
		if (rxBuffer != NULL) rxBuffer[count] = received;
		count++;
		
		if (count < length) {
			post send();
		} else {
			// we release the busy flag before signalling, so copy the pointers
			uint8_t* tx = txBuffer;
			uint8_t* rx = rxBuffer;
			atomic busy = FALSE;
			
			signal SpiPacket.sendDone(tx, rx, length, SUCCESS);
		}
	}
	
	/**
	 * Send a message over the SPI bus.
	*
	 * @param txBuf A pointer to the buffer to send over the bus. If this
	 *              parameter is NULL, then the SPI will send zeroes.
	 * @param rxBuf A pointer to the buffer where received data should
	 *              be stored. If this parameter is NULL, then the SPI will
	 *              discard incoming bytes.
	 * @param len   Length of the message.  Note that non-NULL rxBuf and txBuf
	 *              parameters must be AT LEAST as large as len, or the SPI
	 *              will overflow a buffer.
	 *
	 * @return SUCCESS if the request was accepted for transfer
	 */
	async command error_t SpiPacket.send(uint8_t* txBuf, uint8_t* rxBuf, uint16_t len) {
		atomic {
			if (busy) return EBUSY;
			busy = TRUE;
		}
		
		txBuffer = txBuf;
		rxBuffer = rxBuf;
		length = len;
		count = 0;
		
		post send();
		return SUCCESS;
	}
	
	// fake a Resource implementation
	
	task void grant() {
		signal Resource.granted();
	}
	
	async command error_t Resource.request() {
		init();
		post grant();
		return SUCCESS;
	}
	
	async command error_t Resource.immediateRequest() {
		init();
		return SUCCESS;
	}
	
	async command error_t Resource.release() {
		return SUCCESS;
	}
	
	async command bool Resource.isOwner() {
		return TRUE;
	}
	
	default async event void SpiPacket.sendDone(uint8_t* txBuf, uint8_t* rxBuf, uint16_t len, error_t error) {}
	default event void Resource.granted() {}
}
