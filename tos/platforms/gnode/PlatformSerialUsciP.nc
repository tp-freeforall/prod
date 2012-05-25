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

module PlatformSerialUsciP {
	provides interface StdControl;
	provides interface AsyncStdControl;
	provides interface Msp430UartConfigure;
	uses interface Resource;
}

implementation {

	#ifndef PLATFORM_SERIAL_BAUD_RATE
	#define PLATFORM_SERIAL_BAUD_RATE 57600
	#endif
	
	// build up, for example, UBR_4MIHZ_57600
	#define CONCAT2(a, b, c, d) a ## b ## c ## d
	#define CONCAT(a, b, c, d) CONCAT2(a, b, c, d)
	
	msp430_uart_union_config_t msp430_uart_config = {{
		ubr: CONCAT(UBR_, SMCLK_MIHZ, MIHZ_, PLATFORM_SERIAL_BAUD_RATE),
		umctl: CONCAT(UMCTL_, SMCLK_MIHZ, MIHZ_, PLATFORM_SERIAL_BAUD_RATE),
		ucmode: 0,	// UART mode
		ucspb: 0,		// 1 stop bit
		uc7bit: 0,		// 8 data bits
		ucpen: 0,		// no parity
		ucssel: 0x02,	// SMCLK
	}};

	command error_t StdControl.start(){
		return call Resource.immediateRequest();
	}
	
	command error_t StdControl.stop(){
		call Resource.release();
		return SUCCESS;
	}
	
	async command error_t AsyncStdControl.start(){
		return call Resource.immediateRequest();
	}
	
	async command error_t AsyncStdControl.stop(){
		call Resource.release();
		return SUCCESS;
	}
	
	event void Resource.granted(){}

	async command const msp430_uart_union_config_t* Msp430UartConfigure.getConfig() {
		return &msp430_uart_config;
	}
	
}
