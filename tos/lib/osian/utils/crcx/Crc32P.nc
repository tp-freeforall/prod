/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
 * All rights reserved.
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Mark Hays
 */
 
////////////////////////////////////////////////////////////////////////
// Crc32P.nc -- a couple of CRC32 implementations
//
// REFERENCE:
//   http://www.ece.cmu.edu/~koopman/pubs/ray06_crcalgorithms.pdf
//
//   Preprint, Dependable Systems and Networks (DSN), June 25-28
//   2006, Philadelphia PA
//
//   Efficient High Hamming Distance CRCs for Embedded Networks
//
//   Justin Ray, Phillip Koopman, Department of Electrical
//   Enginerring, Carnegie Mellon University, Pittsburgh PA
//
// NOTES:
//   See crc.py for more readable implementations. For documentation,
//   read the above reference (crc.py isn't well commented).
//
//   Also, tos/system/crc.h mentions the need for a reference for its
//   fast CRC16 algorithm (see Crc16P.nc for a ~sane version).
//
//   Turns out that this implementation is the OVTA for CCR16. The
//   above reference and references therein document the OVTA
//   algorithm.
//

module Crc32P {
  provides {
    interface CrcX<uint32_t> as Crc;
  }
}

implementation {
  async command uint32_t Crc.crc(void* buf, uint8_t len) {
    return call Crc.seededCrc(0, buf, len);
  }
  
#ifdef __MSP430__
#warning "Using MSP430 assembly implementation of CRC32"

#ifdef FAST_CRC32

#warning "Using fast 0xE5 CRC polynomial"

  // This is the OVTA implementation of the CRC32sub8 polynomial
  // 0xE5 from the cited reference above. It is very fast. For
  // example, it is 1us/byte faster than OVTA for CRC16 given in
  // Crc16P.nc!
  //
  // 27 clocks per byte -- 6.75us @ 4MHz
  //
  // Given the GCC bug seen in Crc16P, it's safest
  // to make this be a proper function.
  //
  async command __attribute__((noinline))
    uint32_t Crc.seededCrc(uint32_t crc, void *buf, uint8_t len) {
    atomic {
    __asm__ __volatile__(";---------------\n"
			 "; 0xE5 CRC32\n"
			 ";\n"
			 ";  %0: crc\n"
			 ";  %2: buf\n"
			 ";  %3: len\n"
			 "; r10: ndx\n"
			 "; r11: t\n"
			 "1:\n"
			 "cmp.b #0, %[len]\n"
			 "jeq   2f\n"
			 "dec   %[len]\n"
			 "swpb  %B[crc]\n"
			 "mov.b %B[crc], r10\n"
			 "xor   r10, %B[crc]\n"
			 "xor.b @%[buf]+, r10\n"
			 "swpb  %A[crc]\n"
			 "mov.b %A[crc], r11\n"
			 "bis   r11, %B[crc]\n"
			 "xor   r11, %A[crc]\n"
			 "xor   r10, %A[crc]\n"
			 "add   r10, r10\n"
			 "add   r10, r10\n"
			 "xor   r10, %A[crc]\n"
			 "add   r10, r10\n"
			 "add   r10, r10\n"
			 "add   r10, r10\n"
			 "xor   r10, %A[crc]\n"
			 "add   r10, r10\n"
			 "xor   r10, %A[crc]\n"
			 "add   r10, r10\n"
			 "xor   r10, %A[crc]\n"
			 "jmp   1b\n"
			 "2:\n"
			 : [crc] "=r" (crc)
			 : "0" (crc),
			 [buf] "r" (buf),
			 [len] "r" (len)
			 : "r10", "r11");
    };
    return crc;
  }
#else

#warning "Using slower IEEE CRC32 polynomial"

  // This is the VTA version of IEEE CRC32. It has to loop
  // eight times per byte, but avoids shifts of 32-bit
  // quantities inside the loop. Requires a 16 word table.
  //
  // Cannot be reduced to a faster OVTA implementation, per
  // the cited reference (table bits are too dense to be
  // reduced).

  const uint16_t __attribute__((C)) crcTable[16] = {
    0x1db7,
    0x04c1,
    0x3b6e,
    0x0982,
    0x76dc,
    0x1304,
    0xedb8,
    0x2608,
    0xdb70,
    0x4c11,
    0xb6e0,
    0x9823,
    0x7077,
    0x3486,
    0xe0ee,
    0x690c,
  };

  // nesC won't let crcTable be declared spontaneous.
  // Trick nesC.
  uint16_t __attribute__((noinline, spontaneous)) zagnut(int ndx) {
    return crcTable[ndx];
  }

  // 96-144 clocks per byte -- 24-36 us @ 4 MHz
  //
  // Given the GCC bug seen in Crc16P, it's safest
  // to make this be a proper function.
  //
  async command __attribute__((noinline))
    uint32_t Crc.seededCrc(uint32_t crc, void *buf, uint8_t len) {
    atomic {
    __asm__ __volatile__(";  %0: crc\n"
			 ";  %2: buf\n"
			 ";  %3: len\n"
			 "; r10: ndx\n"
			 "; r11: t\n"
			 "1:\n"
			 "cmp.b #0, %[len]\n"
			 "jeq   4f\n"
			 "dec   %[len]\n"
			 "swpb  %B[crc]\n"
			 "mov.b %B[crc], r10\n"
			 "xor   r10, %B[crc]\n"
			 "xor.b @%[buf]+, r10\n"
			 "swpb  %A[crc]\n"
			 "mov.b %A[crc], r11\n"
			 "bis   r11, %B[crc]\n"
			 "xor   r11, %A[crc]\n"
			 "mov   #0, r11\n"
			 "2:\n"
			 "bit   #1, r10\n"
			 "jz    3f\n"
			 "xor   crcTable(r11), %A[crc]\n"
			 "xor   crcTable+2(r11), %B[crc]\n"
			 "3:\n"
			 "add   #4, r11\n"
			 "; clrc  ; NB unnecessary\n"
			 "rrc   r10\n"
			 "cmp   #32, r11\n"
			 "jne   2b\n"
			 "jmp   1b\n"
			 "4:\n"
			 : [crc] "=r" (crc)
			 : "0" (crc),
			 [buf] "r" (buf),
			 [len] "r" (len)
			 : "r10", "r11");
    };
    return crc;
  }
#endif

#else

#warning "Using slow C implementation of CRC32"

#ifdef FAST_CRC32
#warning "Using fast 0xE5 CRC32 polynomial"

  async command uint32_t Crc.seededCrc(uint32_t crc, void *buf, uint8_t len) {
    atomic {
      uint8_t  *p = (uint8_t *) buf;
      uint16_t  ndx;

      while (len--) {
	ndx   = (crc >> 24) ^ *p++;
	crc <<= 8;
	crc  ^= ndx;
	ndx <<= 2;
	crc  ^= ndx;
	ndx <<= 3;
	crc  ^= ndx;
	ndx <<= 1;
	crc  ^= ndx;
	ndx <<= 1;
	crc  ^= ndx;
      }
    };
    return crc;
  }

#else

#if 0
#warning "Using slow IEEE CRC32 polynomial and glacial CRC algorithm"
  async command uint32_t Crc.seededCrc(uint32_t crc, void *buf, uint8_t len) {
    atomic {
      uint8_t *p = (uint8_t *) buf, i;

      while (len--) {
	crc ^= (((uint32_t) (*p++)) << 24);
	for (i = 0; i < 8; i++) {
	  if (crc & (((uint32_t) 0x80) << 24))
	    crc = (crc << 1) ^ 0x04C11DB7UL;
	  else
	    crc = (crc << 1);
	}
      }
    }
    return crc;
  }
#else
#warning "Using slow IEEE CRC32 polynomial and VTA CRC algorithm"

  const uint32_t ctcTable[8] = {
    0x04c11db7UL,
    0x09823b6eUL,
    0x130476dcUL,
    0x2608edb8UL,
    0x4c11db70UL,
    0x9823b6e0UL,
    0x34867077UL,
    0x690ce0eeUL,
  };

  async command uint32_t Crc.seededCrc(uint32_t crc, void *buf, uint8_t len) {
    atomic {
      uint8_t *p = (uint8_t *) buf, i, ndx;

      while (len--) {
	ndx   = (crc >> 24) ^ *p++;
	crc <<= 8;
	for (i = 0; i < 8; i++) {
	  if (ndx & 1)
	    crc ^= crcTable[i];
	  ndx >>= 1;
	}
      }
    }
    return crc;
  }
#endif

#endif

#endif

}

