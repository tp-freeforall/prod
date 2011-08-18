/*
 * Copyright (c) 2009-2010 People Power Company
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Company nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */


/**
 * OSIAN Device Identifier
 * @author David Moss
 * @author Peter Bigot
 */
#ifndef OSIAN_odi_h
#define OSIAN_odi_h

/* Constant class tag values */
typedef enum ODI_Class_e {
  ODI_CLS_Unregistered = 0,
  ODI_CLS_Communications = 1,
  ODI_CLS_Energy = 2,
  // Class 3 is reserved
  ODI_CLS_HealthAndSafety = 4,
  // Class 5 is reserved
  ODI_CLS_Environment = 6,
  // Class 7 is reserved
} ODI_Class_e;

#ifdef NESC
#define NX_(_t) nx_##_t
#else /* NESC */
#define NX_(_t) _t
#endif /* NESC */

/** An ODI is the equivalent of an EUI-64, with extra information to
 * help identify the functionality on the device.  Note that, to be
 * layout-compatible with the EUI-64, this must be a network-endian
 * structure. */
typedef NX_(struct) odi_t {
  /** Organizationally unique identifier obtained from IANA */
  NX_(uint64_t) oui : 24;
  
  /** 1 bit reserved */
  NX_(uint64_t) reserved : 1;
  
  /** 1 if this device can sense something */
  NX_(uint64_t) sensor : 1;
  
  /** 1 if this device can control something */
  NX_(uint64_t) actuator : 1;
  
  /** The device class, one of ODI_Class_e */
  NX_(uint64_t) deviceClass : 3;
  
  /** The device type, defined in odi_types.h */
  NX_(uint64_t) deviceType : 10;
  
  /** The unique ID of this device instance  */
  NX_(uint64_t) id : 24;
  
} odi_t;

typedef NX_(union) odi_u {
  odi_t odi;
  NX_(uint64_t) value;
} odi_u;

/* Include the current set of defined devices */
#include "odi_types.h"

#endif /* OSIAN_odi_h */
