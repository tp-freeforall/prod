/*
 * Copyright (c) 2010-2011 Eric B. Decker
 * Copyright (c) 2009-2010 DEXMA SENSORS SL
 * Copyright (c) 2004-2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 * @author Xavier Orduna <xorduna@dexmatech.com>
 * @author Eric B. Decker <cire831@gmail.com>
 * @author Jordi Soucheiron <jsoucheiron@dexmatech.com>
 *
 * Support the x2 version of the USCI for the TI MSPx2xx (see TI MSP430x2xx
 * Users guide slau144f).
 *
 * The x2 USCI interface is seriously screwy.   USCI port registers are spread
 * out over various places and the interrupts have different modules on the same
 * vector.  This gets cleaned up in the x5 processors but that makes sharing
 * the same code complicated.   The following functional defines tell the story:
 *
 * x1:  __MSP430_HAS_UART0__	usart0 present
 *	__MSP430_HAS_I2C__	usart0 has I2C
 *	__MSP430_HAS_UART1__
 *
 * x2:	__MSP430_HAS_USCI__
 *	__MSP430_HAS_USCI_AB0__	indicates interrupts messy.
 *	__MSP430_HAS_USCI_AB1__
 *
 * x5:	__MSP430_HAS_USCI_A0__	indicates vectors are module specific.
 *	__MSP430_HAS_USCI_B0__
 *	__MSP430_HAS_USCI_A1__
 *	__MSP430_HAS_USCI_B1__	etc.
 */

#ifndef _H_MSP430USCI_H
#define _H_MSP430USCI_H

#if !defined(__MSP430_HAS_USCI__)
#error "msp430usci: processor not supported, currently only supports x2xxx (HAS_USCI)"
#endif

/*
 * The x2 family consists of the msp430f261{6,7,8,9} which provides
 * 2 USCI_As (UART/SPI) and 2 USCI_Bs (SPI/I2C).  These are mapped on a pure
 * hardware naming scheme along with appropriate sharing files which enable
 * arbitration for each h/w module.
 *
 * usciA0: HplMsp430UsciA0, Msp430UartA0, Msp430SpiA0
 *	   Msp430UsciA0C, Msp430UsciSharedA0P (arbitrated)
 *	   dma
 *
 * usciA1: HplMsp430UsciA1, Msp430UartA1, Msp430SpiA1
 *	   Msp430UsciA1C, Msp430UsciSharedA1P (arbitrated)
 *	   dma
 *
 * usciB0: HplMsp430UsciB0, Msp430SpiB0, Msp430I2CB0
 *	   Msp430UsciB0C, Msp430UsciSharedB0P (arbitrated)
 *	   dma
 *
 * usciB1: HplMsp430UsciB1, Msp430SpiB1, Msp430I2CB1
 *	   Msp430UsciB1C, Msp430UsciSharedB1P (arbitrated)
 *	   no dma
 *
 * usciB1 does not support dma because the dma engine can't be triggered
 * on tx/rx data avail.  Not enough bits.
 *
 * Actual mapping between usci h/w and function is done by platform files.
 * ie.  tos/platforms/<platform>/mappings    or
 *      tos/platforms/<platform>/chips/<chip>
 */

// USCI A0: UART, SPI
#define MSP430_HPLUSCIA0_RESOURCE	"Msp430UsciA0.Resource"
#define MSP430_UARTA0_BUS		"Msp430UartA0.Resource"
#define MSP430_SPIA0_BUS		"Msp430SpiA0.Resource"

//#define MSP430_UARTA0_BUS		MSP430_HPLUSCIA0_RESOURCE
//#define MSP430_SPIA0_BUS		MSP430_HPLUSCIA0_RESOURCE

// USCI A1: UART, SPI
#define MSP430_HPLUSCIA1_RESOURCE	"Msp430UsciA1.Resource"
#define MSP430_UARTA1_BUS		"Msp430UartA1.Resource"
#define MSP430_SPIA1_BUS		"Msp430SpiA1.Resource"

//#define MSP430_UARTA1_BUS		MSP430_HPLUSCIA1_RESOURCE
//#define MSP430_SPIA1_BUS		MSP430_HPLUSCIA1_RESOURCE

// USCI B0: SPI,  I2C
#define MSP430_HPLUSCIB0_RESOURCE	"Msp430UsciB0.Resource"
#define MSP430_SPIB0_BUS		"Msp430SpiB0.Resource"
#define MSP430_I2CB0_BUS		"Msp430I2CB0.Resource"

//#define MSP430_SPIB0_BUS		MSP430_HPLUSCIB0_RESOURCE
//#define MSP430_I2CB0_BUS		MSP430_HPLUSCIB0_RESOURCE

// USCI B1: SPI,  I2C
#define MSP430_HPLUSCIB1_RESOURCE	"Msp430UsciB1.Resource"
#define MSP430_SPIB1_BUS		"Msp430SpiB1.Resource"
#define MSP430_I2CB1_BUS		"Msp430I2CB1.Resource"

//#define MSP430_SPIB1_BUS		MSP430_HPLUSCIB1_RESOURCE
//#define MSP430_I2CB1_BUS		MSP430_HPLUSCIB1_RESOURCE


typedef enum {
  USCI_NONE = 0,
  USCI_UART = 1,
  USCI_SPI = 2,
  USCI_I2C = 3
} msp430_uscimode_t;


/************************************************************************************************************
 *
 * UART mode definitions
 *
 */

/*
 * UCAxCTL0, UART control 0, uart mode
 */

typedef struct {
  unsigned int ucsync : 1;   // Synchronous mode enable (0=Asynchronous; 1:Synchronous)
  unsigned int ucmode : 2;   // USCI Mode (00=UART Mode; 01=Idle-Line; 10=Addres-Bit; 11=UART Mode, auto baud rate detection)
  unsigned int ucspb  : 1;   // Stop bit select. Number of stop bits (0=One stop bit; 1=Two stop bits)
  unsigned int uc7bit : 1;   // Charactaer lenght, (0=8-bit data; 1=7-bit data)
  unsigned int ucmsb  : 1;   // endian.  Direction of the rx and tx shift (0=LSB first, 1=MSB first)
  unsigned int ucpar  : 1;   // Parity Select (0=odd parity; 1=Even parity)
  unsigned int ucpen  : 1;   // Parity enable (0=Parity disable; 1=Parity enabled)
} __attribute__ ((packed)) msp430_uctl0_t ;


/*
 * UCAxCTL1, UART control 1, uart mode
 */

typedef struct {
  unsigned int ucswrst  : 1;  //Software reset enable (0=disabled; 1=enabled)
  unsigned int uctxbrk  : 1;  //Transmit break. (0 = no brk; 1 = tx break next frame
  unsigned int uctxaddr : 1;  //Transmit address. (0=next frame transmitted is data; 1=next frame transmitted is an address)
  unsigned int ucdorm   : 1;  //Dormant.  (0 = not dormant; 1 = Dormant, only some chars will set UCAxRXIFG)
  unsigned int ucbrkie  : 1;  //rx break interrupt -enable, 1 = enabled
  unsigned int ucrxeie  : 1;  //rx error interrupt-enable
  unsigned int ucssel   : 2;  //USCI clock source select: (00=UCKL; 01=ACLK; 10=SMCLK; 11=SMCLK
} __attribute__ ((packed)) msp430_uctl1_t ;


//converts from typedefstructs to uint8_t
DEFINE_UNION_CAST(uctl02int,uint8_t,msp430_uctl0_t)
DEFINE_UNION_CAST(int2uctl0,msp430_uctl0_t,uint8_t)
DEFINE_UNION_CAST(uctl12int,uint8_t,msp430_uctl1_t)
DEFINE_UNION_CAST(int2uctl1,msp430_uctl1_t,uint8_t)


/*
 * The usci/uart baud rate mechanism is significantly different
 * than the msp430 usart uart.  See section 15.3.9 of the TI
 * MSP430x2xx Family User's Guide, slau144f for details.
 *
 * For 32768Hz and 1048576Hz, we use UCOS16=0.
 * For higher cpu dco speeds we use oversampling, UCOS16=1.
 *
 * NOTE: keep in mind that baud rates are effected by the submain cpu
 * clock.  On TinyOS platforms this is a power of 2 hz.  TI defines
 * various factory calibration values for decimal MHz.  In other words
 * we don't use the predefined TI values.  To denote this we use MIHZ
 * nomenclature.
 */

typedef enum {
  /* these names are preserved for backward compatibility */
  UBR_32KHZ_1200=0x001B,    UMCTL_32KHZ_1200=0x04,
  UBR_32KHZ_2400=0x000D,    UMCTL_32KHZ_2400=0x0c,
  UBR_32KHZ_4800=0x0006,    UMCTL_32KHZ_4800=0x0e,
  UBR_32KHZ_9600=0x0003,    UMCTL_32KHZ_9600=0x06,  

  /* these names are preserved for backward compatibility */
  UBR_1048MHZ_9600=0x006D,   UMCTL_1048MHZ_9600=0x04,
  UBR_1048MHZ_19200=0x0036,  UMCTL_1048MHZ_19200=0x0a,
  UBR_1048MHZ_38400=0x001B,  UMCTL_1048MHZ_38400=0x04,
  UBR_1048MHZ_57600=0x0012,  UMCTL_1048MHZ_57600=0x0c,
  UBR_1048MHZ_115200=0x0009, UMCTL_1048MHZ_115200=0x02,
  UBR_1048MHZ_128000=0x0008, UMCTL_1048MHZ_128000=0x02,
  UBR_1048MHZ_256000=0x0004, UMCTL_1048MHZ_230400=0x02,

  /*
   * new names for later TI processors (x2xxx, msp430f261x).
   *
   * 1MIHZ = 1048576 Hz, 4MIHZ 4194304, 8MIHZ 8388608
   * 16MIHZ 16777216.   use UCOS16 for oversampling,
   * use both UCBRF and UCBRS.
   *
   * There is a table on page 15-22 of slau144f, MSP430x2xx family User's Guide
   * but these are mostly powers of 10.   TinyOS clocks are binary so we can't
   * use these.
   */

  UBR_1MIHZ_9600=0x6,       UMCTL_1MIHZ_9600=0xd1,
  UBR_1MIHZ_19200=0x3,      UMCTL_1MIHZ_19200=0x71,
  UBR_1MIHZ_57600=0x1,      UMCTL_1MIHZ_57600=0x21,

  UBR_4MIHZ_4800=0x36,      UMCTL_4MIHZ_4800=0xa1,
  UBR_4MIHZ_9600=0x1B,      UMCTL_4MIHZ_9600=0x51,
  UBR_4MIHZ_19200=0x0D,     UMCTL_4MIHZ_19200=0xa1,
  UBR_4MIHZ_38400=0x06,     UMCTL_4MIHZ_38400=0xd1,
  UBR_4MIHZ_57600=0x04,     UMCTL_4MIHZ_57600=0x91,
  UBR_4MIHZ_115200=0x02,    UMCTL_4MIHZ_115200=0x41,
  UBR_4MIHZ_230400=0x01,    UMCTL_4MIHZ_230400=0x21,

  UBR_8MIHZ_4800=0x6D,      UMCTL_8MIHZ_4800=0x41,
  UBR_8MIHZ_9600=0x36,      UMCTL_8MIHZ_9600=0xA1,
  UBR_8MIHZ_19200=0x1B,     UMCTL_8MIHZ_19200=0x51,
  UBR_8MIHZ_38400=0x0D,     UMCTL_8MIHZ_38400=0xA1,
  UBR_8MIHZ_57600=0x09,     UMCTL_8MIHZ_57600=0x21,
  UBR_8MIHZ_115200=0x04,    UMCTL_8MIHZ_115200=0x91,
  UBR_8MIHZ_230400=0x02,    UMCTL_8MIHZ_230400=0x41,

  UBR_16MIHZ_4800=0xDA,     UMCTL_16MIHZ_4800=0x71,
  UBR_16MIHZ_9600=0x6D,     UMCTL_16MIHZ_9600=0x41,
  UBR_16MIHZ_19200=0x36,    UMCTL_16MIHZ_19200=0xA1,
  UBR_16MIHZ_38400=0x1B,    UMCTL_16MIHZ_38400=0x51,
  UBR_16MIHZ_57600=0x12,    UMCTL_16MIHZ_57600=0x31,
  UBR_16MIHZ_115200=0x9,    UMCTL_16MIHZ_115200=0x21,
  UBR_16MIHZ_230400=0x4,    UMCTL_16MIHZ_230400=0x91,
} msp430_uart_rate_t;


typedef struct {
  unsigned int ubr: 16;		// Baud rate (use enum msp430_uart_rate_t for predefined rates)
  unsigned int umctl: 8;	// Modulation (use enum msp430_uart_rate_t for predefined rates)

  /* start of ctl0 */
  unsigned int : 1;		// ucsync, should be 0 for uart
  unsigned int ucmode: 2;       // mode: 00 - uart, 01 - Idle, 10 - addr bit, 11 - auto baud.
  unsigned int ucspb: 1;	// stop: 0 - one, 1 - two
  unsigned int uc7bit: 1;	// 7 or 8 bit
  unsigned int : 1;		// msb or lsb first, 0 says lsb, uart should be 0
  unsigned int ucpar: 1;	// par, 0 odd, 1 even
  unsigned int ucpen: 1;	// par enable, 0 disabled

  /* start of ctl1 */
  unsigned int : 5;		// not specified, defaults to 0.
  unsigned int ucrxeie: 1;	// rx err int enable
  unsigned int ucssel: 2;	// clock select, 00 uclk, 01 aclk, 10/11 smclk
  
  /* ume, not a control register, backward compatible with usart?
   * should be okay to nuke.  Is this actually used?
   */
  unsigned int utxe:1;			// 1:enable tx module
  unsigned int urxe:1;			// 1:enable rx module
} msp430_uart_config_t;

typedef struct {
  uint16_t ubr;
  uint8_t  umctl;
  uint8_t  uctl0;
  uint8_t  uctl1;
  uint8_t  ume;
} msp430_uart_registers_t;

typedef union {
  msp430_uart_config_t    uartConfig;
  msp430_uart_registers_t uartRegisters;
} msp430_uart_union_config_t;


/*
 * be sure to check Msp430DcoSpec.h for what speed we think
 * the processor is actually running at.  We assume 8MiHz.
 */
const msp430_uart_union_config_t msp430_uart_default_config = { {
  ubr     :	UBR_8MIHZ_115200,
  umctl   :	UMCTL_8MIHZ_115200,
  ucmode  :	0,			// uart
  ucspb   :	0,			// one stop
  uc7bit  :	0,			// 8 bit
  ucpar   :	0,			// odd parity (but no parity)
  ucpen   :	0,			// parity disabled
  ucrxeie :	0,			// err int off
  ucssel  :	2,			// smclk
  utxe    :	1,			// enable tx
  urxe    :	1,			// enable rx
} };


/************************************************************************************************************
 *
 * SPI mode definitions
 *
 */

typedef struct {
  unsigned int ubr    : 16;	// Clock division factor (> = 1)

  /* ctl0 */
  unsigned int        : 1;	// ucsync, forced to 1 by initilization code.
  unsigned int ucmode : 2;	// 00 3pin spi, 01 4pin ste ah, 10 ste al, 11 i2c
  unsigned int ucmst  : 1;	// 0 slave, 1 master
  unsigned int uc7bit : 1;	// 0 8 bit, 1 7 bit.
  unsigned int ucmsb  : 1;	// 0 lsb first, 1 msb first
  unsigned int ucckpl : 1;	// 0 inactive low, 1 inactive high
  unsigned int ucckph : 1;	// 0 tx rising uclk, captured falling
				// 1 captured rising, sent falling edge.
  /* ctl1 */
  unsigned int        : 1;	// ucswrst, forced to 1 on init
  unsigned int        : 5;	// unused.
  unsigned int ucssel : 2;	// BRCLK src, 00 NA, 01 ACLK, 10/11 SMCLK
} msp430_spi_config_t;


typedef struct {
  uint16_t ubr;
  uint8_t  uctl0;
  uint8_t  uctl1;
} msp430_spi_registers_t;

typedef union {
  msp430_spi_config_t spiConfig;
  msp430_spi_registers_t spiRegisters;
} msp430_spi_union_config_t;


const msp430_spi_union_config_t msp430_spi_default_config = { {
  ubr		: 2,			/* smclk/2   */
  ucmode	: 0,			/* 3 pin, no ste */
  ucmst		: 1,			/* master */
  uc7bit	: 0,			/* 8 bit */
  ucmsb		: 1,			/* msb first, compatible with msp430 usart */
  ucckpl	: 0,			/* inactive state low */
  ucckph	: 1,			/* data captured on rising, changed falling */
  ucssel	: 2,			/* smclk */
} };
    
    
/************************************************************************************************************
 *
 * I2C mode definitions
 *
 */

typedef struct {
  unsigned int         : 1;	// Sync mode enable, 1 = sync, must be 1 for i2c
  unsigned int ucmode  : 2;	// 11 for i2c
  unsigned int ucmst   : 1;	// 0 slave, 1 master
  unsigned int         : 1;	// unused
  unsigned int ucmm    : 1;	// multi master mode
  unsigned int ucsla10 : 1;	// slave addr 7 or 10 bit
  unsigned int uca10   : 1;	// own addr   7 or 10 bit
} __attribute__ ((packed)) msp430_i2cctl0_t ;


DEFINE_UNION_CAST(i2cctl02int,uint8_t,msp430_i2cctl0_t)
DEFINE_UNION_CAST(int2i2cctl0,msp430_i2cctl0_t,uint8_t)


typedef struct {
  unsigned int ucswrst  : 1;	// Software reset (1 = reset)
  unsigned int uctxstt  : 1;	// Transmit start in master.
  unsigned int uctxstp  : 1;	// Transmit stop in master.
  unsigned int uctxnack : 1;	// transmit nack
  unsigned int uctr     : 1;	// 0 rx, 1 tx
  unsigned int          : 1;	// unused
  unsigned int ucssel   : 2;	// USCI clock source: (00 UCLKI; 01 ACLK; 10/11 SMCLK
} __attribute__ ((packed)) msp430_i2cctl1_t ;


typedef struct {
  uint16_t ubr    : 16;			/* baud rate divisor */

  /* ctl0 */
  uint8_t         : 1;			/* ucsync, forced to 1 by init code */
  uint8_t ucmode  : 2;			/* mode, must be 3 for i2c */
  uint8_t ucmst   : 1;			/* master if 1 */
  uint8_t         : 1;			/* unused */
  uint8_t ucmm    : 1;			/* mult-master mode */
  uint8_t ucsla10 : 1;			/* slave addr 10 bits vs. 7 */
  uint8_t uca10   : 1;			/* own addressing mode 10 bits vs. 7 */

  /* ctl1 */
  uint8_t         : 1;			/* software reset */
  uint8_t         : 1;			/* gen tx start */
  uint8_t         : 1;			/* gen tx stop */
  uint8_t         : 1;			/* gen nack */
  uint8_t uctr    : 1;			/* tx/rx mode, 1 = tx */
  uint8_t         : 1;			/* unused */
  uint8_t ucssel  : 2;			/* clock src, 00 uclk, 01 aclk, 10/11 smclk */

  /* own addr */
  uint16_t i2coa  : 10;			/* own address */
  uint8_t         : 5;			/* unused */
  uint8_t ucgcen  : 1;			/* general call response enable */
} msp430_i2c_config_t;
    
typedef struct {
  uint16_t ubr;				/* 16 bit baud rate */
  uint8_t  uctl0;			/* control word 0 */
  uint8_t  uctl1;			/* control word 1 */
  uint16_t ui2coa;			/* own address, ucgcen */
} msp430_i2c_registers_t;

typedef union {
  msp430_i2c_config_t i2cConfig;
  msp430_i2c_registers_t i2cRegisters;
} msp430_i2c_union_config_t;


const msp430_i2c_union_config_t msp430_i2c_default_config = { {
    ubr     : 2,			/* smclk/2 */
    ucmode  : 3,			/* i2c mode */
    ucmst   : 1,			/* master */
    ucmm    : 0,			/* single master */
    ucsla10 : 1,			/* 10 bit slave */
    uca10   : 1,			/* 10 bit us */
    uctr    : 1,			/* tx mode to start */
    ucssel  : 2,			/* smclk */
    i2coa   : 1,			/* our address is 1 */
    ucgcen  : 1,			/* respond to general call */
  } };

#endif	/* _H_MSP430USCI_H */
