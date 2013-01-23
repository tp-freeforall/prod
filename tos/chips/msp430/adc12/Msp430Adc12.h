/*
 * Copyright (c) 2013, Eric B. Decker
 * Copyright (c) 2011, Eric B. Decker
 * Copyright (c) 2010, People Power Co.
 * Copyright (c) 2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */
 
#ifndef MSP430ADC12_H
#define MSP430ADC12_H
#include "Msp430RefVoltGenerator.h"

#if !defined(__msp430_have_adc12)
#if !defined(__MSP430_HAS_ADC12__)
#if !defined(__MSP430_HAS_ADC12_PLUS__)
#error Target msp430 device does not have ADC12 module
#endif
#endif
#endif

/*
 * ADC12_USE_PLATFORM_ADC: Assume the platform defines a PlatformAdcC
 * component that provides the necessary timer and IO pin interfaces.
 *
 * ADC12_PINS_AVAILABLE: The number of pins available on the hardware.
 * If not defined, defaults to 8.
 *
 * ADC12_PIN_AUTO_CONFIGURE: Define to automatically configure all
 * available pins.  Only applies if ADC12_USE_PLATFORM_ADC is defined;
 * otherwise refer to ADC12_P6PIN_AUTO_CONFIGURE.
 */

#define ADC12_TIMERA_ENABLED
#define ADC12_P6PIN_AUTO_CONFIGURE
#define ADC12_CHECK_ARGS
//#define ADC12_ONLY_WITH_DMA

#ifndef ADC12_PINS_AVAILABLE
#define ADC12_PINS_AVAILABLE 8
#endif /* ADC12_PINS_AVAILABLE */

// for HIL clients 
#define REF_VOLT_AUTO_CONFIGURE

typedef struct { 
  // see README.txt
  unsigned int inch: 5;            // input channel 
  unsigned int sref: 3;            // reference voltage 
  unsigned int ref2_5v: 1;         // reference voltage level 
  unsigned int adc12ssel: 2;       // clock source sample-hold-time 
  unsigned int adc12div: 3;        // clock divider sample-hold-time 
  unsigned int sht: 4;             // sample-hold-time
  unsigned int sampcon_ssel: 2;    // clock source sampcon signal 
  unsigned int sampcon_id: 2;      // clock divider sampcon 
  unsigned int : 0;                // align to a word boundary 
} msp430adc12_channel_config_t;

typedef struct 
{
  // see README.txt
  volatile unsigned
  inch: 4,                                     // input channel
  sref: 3,                                     // reference voltage
  eos: 1;                                      // end of sequence flag
} __attribute__ ((packed)) adc12memctl_t;

enum inch_enum
{  
   // see device specific data sheet which pin Ax is mapped to
   INPUT_CHANNEL_A0 = 0,                    // input channel A0 
   INPUT_CHANNEL_A1 = 1,                    // input channel A1
   INPUT_CHANNEL_A2 = 2,                    // input channel A2
   INPUT_CHANNEL_A3 = 3,                    // input channel A3
   INPUT_CHANNEL_A4 = 4,                    // input channel A4
   INPUT_CHANNEL_A5 = 5,                    // input channel A5
   INPUT_CHANNEL_A6 = 6,                    // input channel A6
   INPUT_CHANNEL_A7 = 7,                    // input channel A7
   EXTERNAL_REF_VOLTAGE_CHANNEL = 8,        // VeREF+ (input channel 8)
   REF_VOLTAGE_NEG_TERMINAL_CHANNEL = 9,    // VREF-/VeREF- (input channel 9)
   TEMPERATURE_DIODE_CHANNEL = 10,          // Temperature diode (input channel 10)
   SUPPLY_VOLTAGE_HALF_CHANNEL = 11,        // (AVcc-AVss)/2
   INPUT_CHANNEL_A12 = 12,                  // input channel A12
   INPUT_CHANNEL_A13 = 13,                  // input channel A13
   INPUT_CHANNEL_A14 = 14,                  // input channel A14
   INPUT_CHANNEL_A15 = 15,                  // input channel A15
   INPUT_CHANNEL_NONE,                      // illegal (identifies invalid settings)
};

enum sref_enum
{
   REFERENCE_AVcc_AVss = 0,                 // VR+ = AVcc   and VR-= AVss
   REFERENCE_VREFplus_AVss = 1,             // VR+ = VREF+  and VR-= AVss
   REFERENCE_VeREFplus_AVss = 2,            // VR+ = VeREF+ and VR-= AVss
   REFERENCE_AVcc_VREFnegterm = 4,          // VR+ = AVcc   and VR-= VREF-/VeREF- 
   REFERENCE_VREFplus_VREFnegterm = 5,      // VR+ = VREF+  and VR-= VREF-/VeREF-   
   REFERENCE_VeREFplus_VREFnegterm = 6      // VR+ = VeREF+ and VR-= VREF-/VeREF-
};

enum ref2_5v_enum
{
  REFVOLT_LEVEL_1_5 = 0,                    // reference voltage of 1.5 V
  REFVOLT_LEVEL_2_5 = 1,                    // reference voltage of 2.5 V
  REFVOLT_LEVEL_NONE = 0,                   // if e.g. AVcc is chosen 
};

enum adc12ssel_enum
{
   SHT_SOURCE_ADC12OSC = 0,                // ADC12OSC
   SHT_SOURCE_ACLK = 1,                    // ACLK
   SHT_SOURCE_MCLK = 2,                    // MCLK
   SHT_SOURCE_SMCLK = 3                    // SMCLK
};

enum adc12div_enum
{
   SHT_CLOCK_DIV_1 = 0,                         // ADC12 clock divider of 1
   SHT_CLOCK_DIV_2 = 1,                         // ADC12 clock divider of 2
   SHT_CLOCK_DIV_3 = 2,                         // ADC12 clock divider of 3
   SHT_CLOCK_DIV_4 = 3,                         // ADC12 clock divider of 4
   SHT_CLOCK_DIV_5 = 4,                         // ADC12 clock divider of 5
   SHT_CLOCK_DIV_6 = 5,                         // ADC12 clock divider of 6
   SHT_CLOCK_DIV_7 = 6,                         // ADC12 clock divider of 7
   SHT_CLOCK_DIV_8 = 7,                         // ADC12 clock divider of 8
};

enum sht_enum
{
   SAMPLE_HOLD_4_CYCLES = 0,         // sampling duration is 4 clock cycles
   SAMPLE_HOLD_8_CYCLES = 1,         // ...
   SAMPLE_HOLD_16_CYCLES = 2,         
   SAMPLE_HOLD_32_CYCLES = 3,         
   SAMPLE_HOLD_64_CYCLES = 4,         
   SAMPLE_HOLD_96_CYCLES = 5,        
   SAMPLE_HOLD_128_CYCLES = 6,        
   SAMPLE_HOLD_192_CYCLES = 7,        
   SAMPLE_HOLD_256_CYCLES = 8,        
   SAMPLE_HOLD_384_CYCLES = 9,        
   SAMPLE_HOLD_512_CYCLES = 10,        
   SAMPLE_HOLD_768_CYCLES = 11,        
   SAMPLE_HOLD_1024_CYCLES = 12       
};

enum sampcon_ssel_enum
{
   SAMPCON_SOURCE_TACLK = 0,        // Timer A clock source is (external) TACLK
   SAMPCON_SOURCE_ACLK = 1,         // Timer A clock source ACLK
   SAMPCON_SOURCE_SMCLK = 2,        // Timer A clock source SMCLK
   SAMPCON_SOURCE_INCLK = 3,        // Timer A clock source is (external) INCLK
};

enum sampcon_id_enum
{
   SAMPCON_CLOCK_DIV_1 = 0,             // SAMPCON clock divider of 1
   SAMPCON_CLOCK_DIV_2 = 1,             // SAMPCON clock divider of 2
   SAMPCON_CLOCK_DIV_4 = 2,             // SAMPCON clock divider of 4
   SAMPCON_CLOCK_DIV_8 = 3,             // SAMPCON clock divider of 8
};

// The unique string for allocating ADC resource interfaces
#define MSP430ADC12_RESOURCE "Msp430Adc12C.Resource"

// The unique string for accessing HAL2
#define ADCC_SERVICE "AdcC.Service"

// The unique string for accessing HAL2 via ReadStream
#define ADCC_READ_STREAM_SERVICE "AdcC.ReadStream.Client"


#ifdef __MSP430_TI_HEADERS__
  // "The bitfield structures that overlay peripheral registers are not part of
  // mspgcc in the future; the recommended way of accessing those fields is to
  // use the masks defined in the TI headers."
  // (https://www.millennium.berkeley.edu/pipermail/tinyos-devel/2011-March/004804.html)
  //
  // Older versions of cpu header files included register definitions using bit field
  // structures.   Current versions using TI_HEADERS no longer include these bit field
  // structure definitions.
  //
  // One could rewrite the drivers to use masks as is recommended in the tinyos-devel
  // excerpt listed above.  Technically there is nothing wrong with using bit fields
  // as long as they work (there have been problems in different versions of the compiler).
  // The big problem with bit fields is endianess and portability (related) but neither
  // of those issues should be a problem here.
  //
  // It has been verified that the definitions of the ADC12
  // flags has not changed over the different MSP430 chip variants that have an
  // ADC12, i.e. using common structs is safe (verified for the header files
  // installed via package msp430mcu-tinyos version 20110613-20110821).
  // (http://mail.millennium.berkeley.edu/pipermail/tinyos-2.0wg/2011-August/003861.html)
  //
  // So it is left as an exercise for the student to reimplement the driver if someone
  // feels it is worth the time to do so.
  //
  // Be sure to check the generated code with a current compiler (which are in flux).

typedef struct {
  volatile unsigned
    adc12sc:1,
    enc:1,
    adc12tovie:1,
    adc12ovie:1,
    adc12on:1,
    refon:1,
    r2_5v:1,
    msc:1,
    sht0:4,
    sht1:4;
volatile unsigned int : 0; // align to word boundary (saves significant amount of code)
} __attribute__ ((packed)) adc12ctl0_t;

typedef struct {
  volatile unsigned
    adc12busy:1,
    conseq:2,
    adc12ssel:2,
    adc12div:3,
    issh:1,
    shp:1,
    shs:2,
    cstartadd:4;
volatile unsigned int : 0; // align to word boundary (saves significant amount of code)
} __attribute__ ((packed)) adc12ctl1_t;


#ifdef __MSP430_HAS_ADC12_PLUS__

typedef struct {
  volatile unsigned
    bit0:1,
    bit1:1,
    bit2:1,
    bit3:1,
    bit4:1,
    bit5:1,
    bit6:1,
    bit7:1,
    bit8:1,
    bit9:1,
    bit10:1,
    bit11:1,
    bit12:1,
    bit13:1,
    bit14:1,
    bit15:1;
} __attribute__ ((packed)) adc12xflg_t;

/* The adc12 declaration itself */
struct adc12_t {
  adc12ctl0_t ctl0;
  adc12ctl1_t ctl1;
  adc12xflg_t ifg;
  adc12xflg_t ie;
  adc12xflg_t iv;
};

#endif	/* __MSP430_HAS_ADC12_PLUS__ */

/*
 * TI's headers are not consistent.   There are several
 * headers for cpus that define __MSP430_HAS_ADC12__
 * but doesn't define ADC12ENC.  Rather it defines ENC.
 *
 * Same applies to ADC12CONSEQ{0,1}.   There are many others
 * which aren't currently used, the TI headers are seriously
 * confused, something using ENC sometimes ADC12ENC, ADC12ENC
 * is correct.   If more are used because of changes in the
 * driver it is recommended that these tweaks be pulled out
 * into their own file which then gets included here.
 *
 * Fix it here.   Note that we are protected from picking
 * up a wrong value for ENC because we check to see if
 * this cpu explicitly has the ADC12 h/w.
 */

#ifndef ADC12ENC
#define ADC12ENC ENC
#endif

#ifndef ADC12CONSEQ0
#define ADC12CONSEQ0 CONSEQ0
#endif

#ifndef ADC12CONSEQ1
#define ADC12CONSEQ1 CONSEQ1
#endif

#endif		/* __MSP430_TI_HEADERS__ */

#if __GNUC__ >= 4
/*
 * at one point (3.2.3 timeframe) someone noted that there was problems
 * with the bitfield code gen.   What exactly wasn't documented.  No
 * problems have been noticed but you might want to keep an eye out.
 *
 * As of 4.6.3 and 4.7 do not bitch.
 *
 * #warning "ADC12 periph_reg bitfields: mspgcc >= 4 (check bitfield code gen)."
 */
#else
  /* Test for GCC bug (bitfield access) - only version 3.2.3 is known to be stable */
  #define GCC_VERSION (__GNUC__ * 100 + __GNUC_MINOR__ * 10 + __GNUC_PATCHLEVEL__)
  #if GCC_VERSION == 332
    #error "This msp430-gcc version (3.3.2) is known to contain a bug when accessing bitfield structs."
  #elif GCC_VERSION != 323
    #warning "This version of msp430-gcc might contain a bug when accessing bitfield structs (version 3.2.3 is safe - anything else is on your own risk)"
  #endif  

#endif		/* __GNUC__ >= 4 */

#endif		/* MSP430ADC12_H */
