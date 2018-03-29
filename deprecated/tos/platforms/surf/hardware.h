/*
 * Copyright (c) 2011 Eric B. Decker
 * Copyright (c) 2009-2010 People Power Co.
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
 * @author Peter Bigot
 * @author Eric B. Decker <cire831@gmail.com>
 */

#ifndef _H_hardware_h
#define _H_hardware_h

#include "msp430hardware.h"

// enum so components can override power saving,
// as per TEP 112.
enum {
  TOS_SLEEP_NONE = MSP430_POWER_ACTIVE,
};

/* Translate specific revision variant information into an indication
 * of the generic revision. */
#if defined(SURF_REV_B1) && ! defined(SURF_REV_B)
#define SURF_REV_B 1
#endif /* SURF_REV_B1 */
#if defined(SURF_REV_B2) && ! defined(SURF_REV_B)
#define SURF_REV_B 2
#endif /* SURF_REV_B2 */

#if WITH_OSIAN

#include "odi.h"
#include "odi_types.h"

#ifndef OSIAN_DEVICE_SENSOR
#define OSIAN_DEVICE_SENSOR 1
#endif /* OSIAN_DEVICE_SENSOR */
#ifndef OSIAN_DEVICE_ACTUATOR
#define OSIAN_DEVICE_ACTUATOR 1
#endif /* OSIAN_DEVICE_ACTUATOR */
#ifndef OSIAN_DEVICE_CLASS
#define OSIAN_DEVICE_CLASS ODI_CLS_Communications
#endif /* OSIAN_DEVICE_CLASS */
#ifndef OSIAN_DEVICE_TYPE
#define OSIAN_DEVICE_TYPE ODI_COMM_SuRF
#endif /* OSIAN_DEVICE_TYPE */

#endif /* WITH_OSIAN */

/* Use the PlatformAdcC component, and enable 6 pins */
#define ADC12_USE_PLATFORM_ADC 1
#define ADC12_PIN_AUTO_CONFIGURE 1
#define ADC12_PINS_AVAILABLE 6

/*
 * The cc430f5137 includes the RF1A.   When the radio is being used
 * the PMM VCORE setting must be at or abore 2.
 */

#define RADIO_VCORE_LEVEL 2

#endif // _H_hardware_h
