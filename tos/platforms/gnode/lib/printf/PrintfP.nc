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

/**
 * Captures output from printf() and puts characters into a buffer,
 * which is then written to the UART.
 */
generic module PrintfP(uint16_t bufsize) {
	
	provides {
		interface PrintfFlush;
	}
	
	uses {
		interface OutputStream;
		interface UartByte;
		interface Putchar;
	}
}

implementation {

	#define OVERFLOW_WARNING "\r\n* WARNING: printf() buffer overflow\r\n"
	
	uint8_t buffer[bufsize];
	uint16_t start;		// start of unsent data in buffer
	uint16_t length;	// number of unsent bytes in buffer
	uint16_t sendingLength;	// number of bytes currently being sent
	bool overflow;	// set if characters are dropped due to the buffer being full
	bool busy;			// set while sending

	enum {
		ASSERT_PRINTF_SEND = unique(UQ_ASSERT),
		ASSERT_PRINTF_SEND_DONE = unique(UQ_ASSERT),
		ASSERT_PRINTF_OUT_OF_BOUNDS = unique(UQ_ASSERT),
	};
	
	void write(uint8_t* str, uint16_t len) {
		error_t result = call OutputStream.write(str, len);
		assertSuccess(result, ASSERT_PRINTF_SEND);
	}
	
	task void send() {
		atomic {
			// make sure we have bytes to send before continuing,
			// because an earlier run of the task may already have sent the entire buffer
			// (and UartStream.send() returns FAIL when given 0 bytes to send)
			if (busy || length == 0) return;
			busy = TRUE;
			
			if (overflow) {
				write((uint8_t*) OVERFLOW_WARNING, strlen(OVERFLOW_WARNING));
				overflow = FALSE;
				sendingLength = 0;
			} else {
				if (start + length > bufsize) {
					// send the chunk from start to the end of the buffer
					sendingLength = bufsize - start;
					write(&buffer[start], sendingLength);
				} else {
					// no wraparound, so we can send everything in one go
					sendingLength = length;
					write(&buffer[start], sendingLength);
				}
			}
		}
	}
	
	/**
	 * This is where printf() delivers its output. Put it in a buffer for subsequent sending.
	 */
	async event void Putchar.putchar(uint8_t c) {
		atomic {
			assert(start < bufsize, ASSERT_PRINTF_OUT_OF_BOUNDS);
			assert(length <= bufsize, ASSERT_PRINTF_OUT_OF_BOUNDS);
			
			if (length == bufsize) {
				overflow = TRUE;
			} else {
				buffer[(start + length) % bufsize] = c;
				length++;
			}
		}
		
		post send();
	}

	void printNow(char* s, uint16_t len) {
		uint16_t i;
		for (i = 0; i < len; i++) {
			call UartByte.send(s[i]);
		}
	}
	
	/**
	 * Hook for flushing the buffer, used by AssertUart.
	 */
	async command void PrintfFlush.flush() {
		atomic {
			if (busy) length += sendingLength;
			printNow("\n+++\n", 5);
			if (start + length > bufsize) {
				printNow((char*) &buffer[start], bufsize - start);
				printNow((char*) &buffer[0], length - (bufsize - start));
			} else {
				printNow((char*) &buffer[start], length);
			}
			printNow("\n+++\n", 5);
		}
	}
	
	event void OutputStream.writeDone(error_t result) {
		assertSuccess(result, ASSERT_PRINTF_SEND_DONE);
		
		atomic {
			busy = FALSE;
			length -= sendingLength;
			start = (start + sendingLength) % bufsize;
			if (length != 0) post send();
		}
	}
	
//	async event void UartStream.receiveDone(uint8_t* buf, uint16_t len, error_t result) {}
//	async event void UartStream.receivedByte(uint8_t byte) {}
	
	default async command error_t UartByte.send(uint8_t byte) {
		return FAIL;
	}
}
