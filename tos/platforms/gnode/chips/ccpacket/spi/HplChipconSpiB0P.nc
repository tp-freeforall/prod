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
 * Provides an optimized hardware implementation of the SPI protocol using USCI B0,
 * based on TI's example code (SLAA325 - http://www.ti.com/lit/zip/slaa325).
 */
module HplChipconSpiB0P {
	provides {
		interface Init;
		interface HplChipconSpi;
	}
	
	uses {
		interface HplMsp430GeneralIO as SIMO;
		interface HplMsp430GeneralIO as SOMI;
		interface HplMsp430GeneralIO as UCLK;		
	}
}
	
implementation {
	
	// wait for TXBUF to become available
	#define WAIT_TX_READY() while (!(IFG2 & UCB0TXIFG))
	
	/**
	 * Configure the USCI.
	 */
	command error_t Init.init() {
		// set USCI reset bit while configuring and clear it afterwards
		UCB0CTL1 |= UCSWRST;
		
		// SPI master mode, 8 bit data, MSB first, phase = 1, polarity = 0
		UCB0CTL0 = UCSYNC + UCMST + UCMSB + UCCKPH;
		
		// clock from SMCLK, keep reset bit high
		UCB0CTL1 = UCSSEL_2 + UCSWRST;
		
		// set clock divisor for "as fast as possible"
		// note that a divisor of 1 is not allowed
		UCB0BR0 = 2;
		UCB0BR1 = 0;
		
		// clear reset bit after reconfiguration
		UCB0CTL1 &= ~UCSWRST;
		
		// disable interrupts (we use polling)
		IE2 &= ~(UCB0TXIE | UCB0RXIE);
		
		// switch I/O pins to SPI mode
		call SIMO.selectModuleFunc(); 
		call SOMI.selectModuleFunc();
		call UCLK.selectModuleFunc();
		
		return SUCCESS;
	}
	
	command uint8_t HplChipconSpi.strobe(uint8_t strobe) {
		uint8_t status;
		WAIT_TX_READY();
		UCB0TXBUF = strobe;			// send strobe
		while (UCB0STAT & UCBUSY);	// wait for TX to complete
		status = UCB0RXBUF;			// read chip status byte
		return status;
	}
	
	command uint8_t HplChipconSpi.readRegister(uint8_t reg) {
		uint8_t value;
		WAIT_TX_READY();
		UCB0TXBUF = reg;			// send address
		WAIT_TX_READY();
		UCB0TXBUF = 0;				// dummy write so we can read data
		while (UCB0STAT & UCBUSY);	// wait for TX to complete
		value = UCB0RXBUF;			// read data
		return value;
	}
	
	command void HplChipconSpi.writeRegister(uint8_t reg, uint8_t value) {
		WAIT_TX_READY();
		UCB0TXBUF = reg;			// send address
		WAIT_TX_READY();
		UCB0TXBUF = value;			// send data
		while (UCB0STAT & UCBUSY);	// wait for TX to complete
	}
	
	command void HplChipconSpi.read(uint8_t addr, uint8_t* buffer, uint8_t len) {
		uint8_t i;

		WAIT_TX_READY();
		UCB0TXBUF = addr;			// Send address
		while (UCB0STAT & UCBUSY);	// Wait for TX to complete
		
		atomic {
			UCB0TXBUF = 0;				// Dummy write to read 1st data byte
			IFG2 &= ~UCB0RXIFG;			// Clear flag
			// Addr byte is now being TX'ed, with dummy byte to follow immediately after
			while (!(IFG2&UCB0RXIFG));		// Wait for end of 1st data byte TX
		}
		
		// First data byte now in RXBUF
		for (i = 0; i < (len-1); i++) {
			// this overlapping sequence only works reliably with interrupts disabled,
			// because an interrupt between writing TX and reading the previous RX byte
			// can cause the while loop to never end
			atomic {
				UCB0TXBUF = 0;			// Initiate next data RX, meanwhile..
				buffer[i] = UCB0RXBUF;		// Store data from last data RX
				while (!(IFG2&UCB0RXIFG));	// Wait for RX to finish
			}
		}
		
		buffer[len-1] = UCB0RXBUF;	// Store last RX byte in buffer
	}
	
	command void HplChipconSpi.write(uint8_t addr, uint8_t* buffer, uint8_t len) {
		uint8_t i;
		WAIT_TX_READY();
		UCB0TXBUF = addr;			// send address
		for (i = 0; i < len; i++) {
			WAIT_TX_READY();
			UCB0TXBUF = buffer[i];		// send data
		}
		
		while (UCB0STAT & UCBUSY);	// wait for TX to complete
	}
}
