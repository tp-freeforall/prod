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

generic module Microchip23AxxxP() {
	provides {
		interface Init;
		interface SRAM;
	}
	
	uses {
		interface SpiByte;
		interface GeneralIO as ChipSelect;
	}
}

implementation {
	
	enum Commands {
		WRSR = 1,	// 0000 0001: Write STATUS register
		WRITE = 2,	// 0000 0010: Write data to memory array beginning at selected address
		READ = 3,	// 0000 0011: Read data from memory array beginning at selected address
		RDSR = 5,	// 0000 0101: Read STATUS register
	};
	
	void send(uint8_t cmd, uint16_t address) {
		call SpiByte.write(cmd);
		call SpiByte.write(address >> 8);
		call SpiByte.write(address >> 0);
	}
	
	void start() {
		call ChipSelect.clr();
	}
	
	void stop() {
		call ChipSelect.set();
	}
	
	command error_t Init.init() {
		uint8_t status;
		
		call ChipSelect.makeOutput();
		call ChipSelect.set();
		
		// select sequential mode: 7:6 = 01b
		start();
		call SpiByte.write(WRSR);
		call SpiByte.write(0x40);
		stop();
		
		// The data sheet says:
		// "Bits 2 through 5 are reserved and should always be set
		// to ‘0’. Bit 1 will read back as ‘1’ but should always be
		// written as ‘0’."
		// so the expected value is 0100 0010 = 0x42
		start();
		call SpiByte.write(RDSR);
		status = call SpiByte.write(0);
		assertEquals(status, 0x42, ASSERT_CANT_HAPPEN);
		stop();
		
		return SUCCESS;
	}
	
	command void SRAM.read(uint16_t address, uint8_t len, void* buffer) {
		uint8_t* bytes = buffer;
		uint8_t i;
		
		start();
		send(READ, address);
		for (i = 0; i < len; i++) {
			bytes[i] = call SpiByte.write(0);
		}
		stop();
	}
	
	command void SRAM.write(uint16_t address, uint8_t len, void* buffer) {
		uint8_t* bytes = buffer;
		uint8_t i;
		start();
		send(WRITE, address);
		for (i = 0; i < len; i++) {
			call SpiByte.write(bytes[i]);
		}
		stop();
	}
	
}