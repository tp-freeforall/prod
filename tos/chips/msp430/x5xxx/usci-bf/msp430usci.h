#ifndef _H_Msp430Usci_h
#define _H_Msp430Usci_h

#include "msp430hardware.h"

#ifndef UCSSEL__SMCLK
/*
 * Both the x2 and x5 families have UCSIs and need a clock source.
 * The x5 cpu header files define UCSSEL__SMCLK but the x2 headers
 * don't  (please TI, can you be more consistent?...   nah.  that's
 * fine, we'll deal)
 *
 * Note: this is x2xxx/usci/msp430usci.h and is inherently a
 * x2 file.
 */
#define UCSSEL__SMCLK       (0x80)    /* USCI 0 Clock Source: SMCLK */
#endif

/* MSP430_USCI_RESOURCE is used for USCI_IDs */
#define MSP430_USCI_RESOURCE "Msp430Usci.Resource"

#define MSP430_USCI_A0_RESOURCE "Msp430Usci.A0.Resource"
#define MSP430_USCI_B0_RESOURCE "Msp430Usci.B0.Resource"
#define MSP430_USCI_A1_RESOURCE "Msp430Usci.A1.Resource"
#define MSP430_USCI_B1_RESOURCE "Msp430Usci.B1.Resource"
#define MSP430_USCI_A2_RESOURCE "Msp430Usci.A2.Resource"
#define MSP430_USCI_B2_RESOURCE "Msp430Usci.B2.Resource"
#define MSP430_USCI_A3_RESOURCE "Msp430Usci.A3.Resource"
#define MSP430_USCI_B3_RESOURCE "Msp430Usci.B3.Resource"

enum {
  MSP430_USCI_Inactive,
  MSP430_USCI_UART,
  MSP430_USCI_SPI,
  MSP430_USCI_I2C,
};

/**
 * Aggregates basic configuration registers for an MSP430 USCI.
 * These are specifically the registers common to all configurations.
 * Mode-specific configuration data should be provided elsewise.
 */
typedef struct msp430_usci_config_t {
  uint8_t ctl0;				/* various control bits, msb */
  uint8_t ctl1;				/* clock select and swreset, lsb */
  uint8_t br0;				/* lsb divider */
  uint8_t br1;				/* msb divider */
  uint8_t mctl;
  uint16_t i2coa;
} msp430_usci_config_t;

// see note in Msp430UsciI2CP.nc I2CBasicAddr.read
// x5 uses 0x500, x2 uses 0xe00 can they be the same?
#define I2C_ONE_BYTE_READ_COUNTER 0x0500

#ifndef TOS_DEFAULT_BAUDRATE
#define TOS_DEFAULT_BAUDRATE 115200
#endif /* TOS_DEFAULT_BAUDRATE */


/*
 * The following default configurations assume SMCLK clock is 1MiHz (2^20Hz).
 */

msp430_usci_config_t msp430_usci_uart_default_config = {
  /* N81 UART mode driven by SMCLK */
  ctl0 : 0,
  ctl1 : UCSSEL__SMCLK,

#if 9600 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 9600: UBR=109, BRS=2, BRF=0 */
  br0  : 109,
  br1  : 0,
  mctl : UCBRF_0 | UCBRS_2,
#elif 19200 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 19200: UBR=54, BRS=2, BRF=0 */
  br0  : 54,
  br1  : 0,
  mctl : UCBRF_0 | UCBRS_2,
#elif 38400 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 38400: UBR=27, BRS=2, BRF=0 */
  br0 : 27,
  br1 : 0,
  mctl : UCBRF_0 | UCBRS_2,
#elif 57600 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 57600: UBR=18, BRS=1, BRF=0 */
  br0  : 18,
  br1  : 0,
  mctl : UCBRF_0 | UCBRS_1,
#elif 115200 == TOS_DEFAULT_BAUDRATE
  /* SLAU259 Table 16-4 2^20Hz 115200: UBR=9, BRS=1, BRF=0 */
  br0  : 9,
  br1  : 0,
  mctl : UCBRF_0 | UCBRS_1,
#else
#warning Unrecognized value for TOS_DEFAULT_BAUDRATE, using 115200
  br0  : 9,
  br1  : 0,
  mctl : UCBRF_0 | UCBRS_1,
#endif
  i2coa: 0
};

msp430_usci_config_t msp430_usci_spi_default_config = {
  /* Inactive high MSB-first 8-bit 3-pin master driven by SMCLK */
  ctl0 : UCCKPL | UCMSB | UCMST | UCSYNC,
  ctl1 : UCSSEL__SMCLK,
  br0  : 2,			/* 2x Prescale */
  br1  : 0,
  mctl : 0,
  i2coa: 0
};

// Should the default be the following?  MM (multi-master) seems
// like it should be a platform specific thing.
// ctl0 : (UCMST | UCMODE_3 | UCSYNC),

msp430_usci_config_t msp430_usci_i2c_default_config = {
  /* 7 bit addressing single I2C master driven by SMCLK */
  ctl0 : UCSYNC | UCMODE_3 | UCMM,
  ctl1 : UCSSEL__SMCLK,
  br0  : 10,		/* 104857 hz, slow for slow devices. */
  br1  : 0,
  mctl : 0,
  i2coa: 0x41,
};

enum {
  /** Bit set in Msp430UsciError.condition parameter when a framing
   * error (UART) or bus conflict (SPI) has been detected.  Applies in
   * UART mode, and SPI 4-wire master mode. */
  MSP430_USCI_ERR_Framing = UCFE,
  /** Bit set in Msp430UsciError.condition parameter when an overrun
   * error (lost character on input) has been detected.  Applies in
   * UART and SPI modes. */
  MSP430_USCI_ERR_Overrun = UCOE,
  /** Bit set in Msp430UsciError.condition parameter when a parity
   * error has been detected.  Applies in UART mode. */
  MSP430_USCI_ERR_Parity = UCPE,
  /** Mask for all UCxySTAT bits that represent reportable errors. */
  MSP430_USCI_ERR_UCxySTAT = MSP430_USCI_ERR_Framing | MSP430_USCI_ERR_Overrun | MSP430_USCI_ERR_Parity,
};

#endif // _H_Msp430Usci_h
