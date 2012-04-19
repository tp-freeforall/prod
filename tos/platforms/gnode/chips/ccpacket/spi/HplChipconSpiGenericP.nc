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
 * Provides a generic implementation of the SPI protocol using an SpiByte provider.
 */
module HplChipconSpiGenericP {
	provides {
		interface HplChipconSpi;
	}
	
	uses {
		interface SpiByte;
		interface SpiByte as WriteOnly;
		interface SpiByte as ReadOnly;
	}
}
	
implementation {
	
	command uint8_t HplChipconSpi.strobe(uint8_t strobe) {
		return call SpiByte.write(strobe);
	}
	
	command uint8_t HplChipconSpi.readRegister(uint8_t reg) {
		call WriteOnly.write(reg);
		return call SpiByte.write(0);
	}
	
	command void HplChipconSpi.writeRegister(uint8_t reg, uint8_t value) {
		call WriteOnly.write(reg);
		call WriteOnly.write(value);
	}
	
	command void HplChipconSpi.read(uint8_t addr, uint8_t* buffer, uint8_t len) {
		uint8_t i;
		call WriteOnly.write(addr);
		for (i = 0; i < len; i++) {
			buffer[i] = call ReadOnly.write(0);
		}
	}
	
	command void HplChipconSpi.write(uint8_t addr, uint8_t* buffer, uint8_t len) {
		uint8_t i;
		call WriteOnly.write(addr);
		for (i = 0; i < len; i++) {
			call WriteOnly.write(buffer[i]);
		}
	}
}
