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

#ifndef CHIPCON_REGISTERS_H
#define CHIPCON_REGISTERS_H

enum { NUM_REGISTERS = 36 };

#ifndef __MSP430_HAS_CC1101__
enum ChipconConfigRegisters {
	FSCTRL1 = 0x0B, // Frequency synthesizer control.
	FSCTRL0 = 0x0C, // Frequency synthesizer control.
	FREQ2 = 0x0D,   // Frequency control word, high byte.
	FREQ1 = 0x0E,   // Frequency control word, middle byte.
	FREQ0 = 0x0F,   // Frequency control word, low byte.
	MDMCFG4 = 0x10, // Modem configuration.
	MDMCFG3 = 0x11, // Modem configuration.
	MDMCFG2 = 0x12, // Modem configuration.
	MDMCFG1 = 0x13, // Modem configuration.
	MDMCFG0 = 0x14, // Modem configuration.
	CHANNR = 0x0A,  // Channel number.
	DEVIATN = 0x15, // Modem deviation setting (when FSK modulation is enabled).
	FREND1 = 0x21,  // Front end RX configuration.
	FREND0 = 0x22,  // Front end RX configuration.
	MCSM1 = 0x17,   // Main Radio Control State Machine configuration.
	MCSM0 = 0x18,   // Main Radio Control State Machine configuration.
	FOCCFG = 0x19,  // Frequency Offset Compensation Configuration.
	BSCFG = 0x1A,   // Bit synchronization Configuration.
	AGCCTRL2 = 0x1B,// AGC control.
	AGCCTRL1 = 0x1C,// AGC control.
	AGCCTRL0 = 0x1D,// AGC control.
	FSCAL3 = 0x23,  // Frequency synthesizer calibration.
	FSCAL2 = 0x24,  // Frequency synthesizer calibration.
	FSCAL1 = 0x25,  // Frequency synthesizer calibration.
	FSCAL0 = 0x26,  // Frequency synthesizer calibration.
	FSTEST = 0x29,  // Frequency synthesizer calibration.
	TEST2 = 0x2C,   // Various test settings.
	TEST1 = 0x2D,   // Various test settings.
	TEST0 = 0x2E,   // Various test settings.
	IOCFG2 = 0x00,  // GDO2 output pin configuration.
	IOCFG0 = 0x02, // GDO0 output pin configuration. Refer to SmartRF® Studio User Manual for detailed pseudo register explanation.
	PKTCTRL1 = 0x07,// Packet automation control.
	PKTCTRL0 = 0x08,// Packet automation control.
	ADDR = 0x09,    // Device address.
	PKTLEN = 0x06,  // Packet length.
	PATABLE = 0x3E,		// PA power control - special register, see data sheet for use.
};

enum StatusRegisters {
	PARTNUM = 0x30,		// Part number for CC1101 
	VERSION = 0x31,		// Current version number
	FREQEST = 0x32,		// Frequency Offset Estimate
	LQI = 0x33,				// Demodulator estimate for Link Quality
	RSSI = 0x34,				// Received signal strength indication
	MARCSTATE = 0x35,	// Control state machine state
	WORTIME1 = 0x36,	// High byte of WOR timer
	WORTIME0 = 0x37,	// Low byte of WOR timer
	PKTSTATUS = 0x38,	// Current GDOx status and packet status
	VCO_VC_DAC = 0x39,	// Current setting from PLL calibration module
	TXBYTES = 0x3A,		// Underflow and number of bytes in the TX FIFO
	RXBYTES = 0x3B,		// Overflow and number of bytes in the RX FIFO
	RCCTRL1_STATUS = 0x3C,	// Last RC oscillator calibration result
	RCCTRL0_STATUS = 0x3D,	// Last RC oscillator calibration result
};

enum FifoAccess {
	TXFIFO = 0x3F,
	RXFIFO = 0xBF,
	TX_BURST_WRITE = 0x7F,
	RX_BURST_READ = 0xFF,
};
#endif // __MSP430_HAS_CC1101__

enum Strobes {
	SRES = 0x30,			// Reset chip.
	SFSTXON = 0x31,	// Enable and calibrate frequency synthesizer (if MCSM0.FS_AUTOCAL=1). If in RX (with CCA):
								// Go to a wait state where only the synthesizer is running (for quick RX / TX turnaround).
	SXOFF = 0x32,		// Turn off crystal oscillator.
	SCAL = 0x33,			// Calibrate frequency synthesizer and turn it off. SCAL can be strobed from IDLE mode without
								// setting manual calibration mode (MCSM0.FS_AUTOCAL=0)
	SRX = 0x34,			// Enable RX. Perform calibration first if coming from IDLE and MCSM0.FS_AUTOCAL=1.
	STX = 0x35,			// In IDLE state: Enable TX. Perform calibration first if MCSM0.FS_AUTOCAL=1.
								// If in RX state and CCA is enabled: Only go to TX if channel is clear.
	SIDLE = 0x36,			// Exit RX / TX, turn off frequency synthesizer and exit Wake-On-Radio mode if applicable.
	SWOR = 0x38,		// Start automatic RX polling sequence (Wake-on-Radio) as described in Section 19.5 if WORCTRL.RC_PD=0.
	SPWD = 0x39,		// Enter power down mode when CSn goes high.
	SFRX = 0x3A,			// Flush the RX FIFO buffer. Only issue SFRX in IDLE or RXFIFO_OVERFLOW states.
	SFTX = 0x3B,			// Flush the TX FIFO buffer. Only issue SFTX in IDLE or TXFIFO_UNDERFLOW states.
	SWORRST = 0x3C,	// Reset real time clock to Event1 value.
	SNOP = 0x3D,		// No operation. May be used to get access to the chip status byte.
};

#endif
