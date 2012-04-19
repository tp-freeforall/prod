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

#ifndef CHIPCON_REGISTER_VALUES_H
#define CHIPCON_REGISTER_VALUES_H

#include "ChipconRegisters.h"
#include "ChipconPacket.h"

// Settings needed by software stack for proper operation -
// make sure these match the register values below! 
enum {
	PREAMBLE_BYTES = 4,		// number of preamble bytes
	SYNC_BYTES = 4,			// number of sync bytes
	CRC_BYTES = 2,			// number of CRC bytes
	RSSI_OFFSET = 74,		// offset applied to the RSSI output, in dB
	EXPECTED_PARTNUM = 0x00,	// expected value of the PARTNUM register
	EXPECTED_VERSION_CC1101 = 0x04,	// expected values of VERSION register
	EXPECTED_VERSION_RF1A = 0x06,		// for CC1101 and RF1A (CC430)
	// BAUD_RATE is defined below, based on data rate and encoding
};

// output power levels in dBm
enum OutputPower {
	POWER_DEFAULT = 0xC6,	// 8.5 dBm
	POWER_MINUS_30 = 0x03,
	POWER_MINUS_20 = 0x0F,
	POWER_MINUS_10 = 0x27,
	POWER_MINUS_5 = 0x67,
	POWER_0 = 0x50,
	POWER_5 = 0x81,
	POWER_7 = 0xCB,
	POWER_10 = 0xC2,
	POWER_12 = 0xC5,
};

// defaults: maximum power, 868 MHz, channel 0, 38400 bps with Manchester encoding
#ifndef CHIPCON_OUTPUT_POWER
#define CHIPCON_OUTPUT_POWER POWER_12
#endif

#ifndef CHIPCON_DATA_RATE
#define CHIPCON_DATA_RATE 38400UL
#endif

#ifndef CHIPCON_MANCHESTER_ENCODING
#define CHIPCON_MANCHESTER_ENCODING 1
#endif

#ifndef CHIPCON_FREQUENCY
#define CHIPCON_FREQUENCY 868
#endif

#ifndef CHIPCON_CHANNEL
#define CHIPCON_CHANNEL 0
#endif

#if CHIPCON_DATA_RATE == 38400UL
	// RX filterbandwidth = 101.562500 kHz
	// Deviation = 19 kHz
	// Datarate = 38.383484 kBaud
	#define _FSCTRL1	0x06
	#define _MDMCFG4	0xCA
	#define _MDMCFG3	0x83
	#define _DEVIATN	0x34
	#define _TEST2		0x81
	#define _TEST1		0x35
#elif CHIPCON_DATA_RATE == 250000UL
	// RX filterbandwidth = 541.666667 kHz
	// Deviation = 127 kHz
	// Datarate = 249.938965 kBaud
	#define _FSCTRL1	0x0C
	#define _MDMCFG4	0x2D
	#define _MDMCFG3	0x3B
	#define _DEVIATN	0x62
	#define _TEST2		0x88
	#define _TEST1		0x31
#else
	#error "Unsupported data rate"
#endif

// Manchester encoding halves the effective data rate but improves sensitivity
#if CHIPCON_MANCHESTER_ENCODING == 1
	#define _MDMCFG2	0x1B
	#define BAUD_RATE (CHIPCON_DATA_RATE/2)
#else
	#define _MDMCFG2	0x13
	#define BAUD_RATE CHIPCON_DATA_RATE
#endif

// In general, relative threshold CS is preferable because it adapts to
// background noise. However, we can't use it with low power listening,
// because then the radio generally won't catch the sudden increase
// or decrease in RSSI as it only briefly samples the channel.
#ifdef LOW_POWER_LISTENING
	// absolute threshold, set at 7 dB under MAGN_TARGET,
	// which is about 5 dB over the sensitivity threshold
	// (varies with data rate, depends on the amplifier gain settings in AGCTRL2)
	#define _AGCCTRL1 0x49
#else
	// relative CS threshold (+10 dB)
	#define _AGCCTRL1 0x68
#endif

// frequency presets
#if CHIPCON_FREQUENCY == 868
	#if CHIPCON_DATA_RATE == 38400UL
		// low speed: 868.3 MHz (sub-band 1)
		#define _FREQ2 0x21
		#define _FREQ1 0x65
		#define _FREQ0 0x6A
	#elif CHIPCON_DATA_RATE == 250000UL
		// high speed: 869.5 MHz (sub-band 6)
		#define _FREQ2 0x21
		#define _FREQ1 0x71
		#define _FREQ0 0x3B
	#else
		#error "Unsupported data rate"
	#endif

#elif CHIPCON_FREQUENCY == 915
	// 915 MHz
	#define _FREQ2 0x23
	#define _FREQ1 0x31
	#define _FREQ0 0x3B
#else
	#error "Unsupported frequency"
#endif

const uint8_t chipconRegisterValues[NUM_REGISTERS * 2] = {
	// Chipcon
	// Product = CC1101
	// Chip version = A   (VERSION = 0x04)
	// Crystal accuracy = 10 ppm
	// X-tal frequency = 26 MHz
	// RF output power = 10 dBm
	// Modulation = (1) 2-GFSK
	// RF Frequency = 868.299866 MHz (default)
	// Channel spacing = 199.951172 kHz
	// Channel number = 0
	// Optimization = -
	// Sync mode = (3) 30/32 sync word bits detected
	// Format of RX/TX data = (0) Normal mode, use FIFOs for RX and TX
	// CRC operation = (1) CRC calculation in TX and CRC check in RX enabled
	// Forward Error Correction = (0) FEC disabled
	// Length configuration = (1) Variable length packets, packet length configured by the first received byte after sync word.
	// Packetlength = 255
	// Preamble count = (2)  4 bytes
	// Append status = 1
	// Address check = (0) No address check
	// FIFO autoflush = 0
	// Device address = 0
	// GDO0 signal selection = (6) Asserts when sync word has been sent / received, and de-asserts at the end of the packet
	// GDO2 signal selection = (9) CCA
	FSCTRL1, _FSCTRL1, // Frequency synthesizer control.
	FSCTRL0, 0x00, // Frequency synthesizer control.
	FREQ2, _FREQ2, // Frequency control word, high byte.
	FREQ1, _FREQ1, // Frequency control word, middle byte.
	FREQ0, _FREQ0, // Frequency control word, low byte.
	MDMCFG4, _MDMCFG4, // Modem configuration.
	MDMCFG3, _MDMCFG3, // Modem configuration.
	MDMCFG2, _MDMCFG2, // Modem configuration.
	MDMCFG1, 0x22, // Modem configuration.
	MDMCFG0, 0xF8, // Modem configuration.
	CHANNR, CHIPCON_CHANNEL, // Channel number.
	DEVIATN, _DEVIATN, // Modem deviation setting (when FSK modulation is enabled).
	FREND1, 0x56, // Front end RX configuration.
	FREND0, 0x10, // Front end RX configuration.
	FOCCFG, 0x16, // Frequency Offset Compensation Configuration.
	BSCFG, 0x6C, // Bit synchronization Configuration.
	AGCCTRL2, 0x43, // AGC control.
	AGCCTRL1, _AGCCTRL1, // AGC control.
	AGCCTRL0, 0x91, // AGC control.
	FSCAL3, 0xE9, // Frequency synthesizer calibration.
	FSCAL2, 0x2A, // Frequency synthesizer calibration.
	FSCAL1, 0x00, // Frequency synthesizer calibration.
	FSCAL0, 0x1F, // Frequency synthesizer calibration.
	FSTEST, 0x59, // Frequency synthesizer calibration.
	TEST2, _TEST2, // Various test settings.
	TEST1, _TEST1, // Various test settings.
	TEST0, 0x09, // Various test settings.
	
	// use as CCA indicator
	IOCFG2, 0x09, // GDO2 output pin configuration.
	
	// asserts when sync word has been sent / received, and de-asserts at the end of the packet
	IOCFG0, 0x06, // GDO0 output pin configuration. Refer to SmartRF® Studio User Manual for detailed pseudo register explanation.
	
	// CRC autoflush on, address checking on
	// PKTCTRL1, 0x0F, // Packet automation control.
	
	// CRC autoflush on, address checking off
	PKTCTRL1, 0x0C, // Packet automation control.
	
	// data whitening on
	PKTCTRL0, 0x45, // Packet automation control.
	
	ADDR, 0x00, // Device address.
	
	// restrict max packet length to what will fit into our message_t, up to 61 bytes (64 bytes FIFO)
	// this does not include the length byte itself
	PKTLEN, MAX_PACKET_LENGTH - 1, // Packet length.
	
	// go to IDLE after TX and go to IDLE after RX
	MCSM1, 0x30, // Main Radio Control State Machine configuration.
	
	// calibrate after going from TX or RX to IDLE
	MCSM0, 0x28, // Main Radio Control State Machine configuration.
	
	PATABLE, CHIPCON_OUTPUT_POWER,	// PA output power.
};

#endif
