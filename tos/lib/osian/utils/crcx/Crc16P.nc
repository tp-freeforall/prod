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
 
// See Crc32P.nc for references

module Crc16P {
  provides {
    interface CrcX<uint16_t> as CRC;
  }
}

implementation {

  async command uint16_t CRC.crc(void* buf, uint8_t len) {
    return call CRC.seededCrc(0, buf, len);
  }

#ifdef __MSP430__

#warning "Using MSP430 assembly implementation of CRC16"

  // This is a bit faster than the C implementation because it
  // doesn't include the bizarre and knuckleheaded stuff that
  // mspgcc generates. For example, mspgcc generates a long
  // and weird+pointless insn sequence for the first "swpb %[crc]"
  // below.
  //
  // 31 clocks per byte -- 7.75us @ 4 MHz
  //
  // GCC bug: things break if you don't include the noinline attribute!
  //
  async command __attribute__((noinline))
    uint16_t CRC.seededCrc(uint16_t crc, void *buf, uint8_t len) {
    atomic {
    __asm__ __volatile__(";---------------\n"
			 "; CRC16\n"
			 ";\n"
			 ";  %0: crc\n"
			 ";  %2: buf\n"
			 ";  %3: len\n"
			 "; r10: scratch\n"
			 "1:\n"
			 "cmp.b #0, %[len]\n"
			 "jeq   2f\n"
			 "dec   %[len]\n"
			 "swpb  %[crc]\n"
			 "mov.b @%[buf]+, r10\n"
			 "xor   r10, %[crc]\n"
			 "mov.b %[crc], r10\n"
			 "clrc\n"
			 "rrc.b r10\n"
			 "rra.b r10\n"
			 "rra.b r10\n"
			 "rra.b r10\n"
			 "xor   r10, %[crc]\n"
			 "mov.b %[crc], r10\n"
			 "swpb  r10\n"
			 "rla   r10\n"
			 "rla   r10\n"
			 "rla   r10\n"
			 "rla   r10\n"
			 "xor   r10, %[crc]\n"
			 "mov.b %[crc], r10\n"
			 "rla   r10\n"
			 "rla   r10\n"
			 "rla   r10\n"
			 "rla   r10\n"
			 "rla   r10\n"
			 "xor   r10, %[crc]\n"
			 "jmp   1b\n"
			 "2:\n"
			 : [crc] "=r" (crc)
			 : "0" (crc),
			 [buf] "r" (buf),
			 [len] "r" (len)
			 : "r10");
    };
    return crc;
  }

#else
#warning "Using slow C implementation of CRC16"
  
  async command uint16_t CRC.seededCrc(uint16_t crc, void *buf, uint8_t len) {
    atomic {
      uint8_t *p = (uint8_t *) buf;

      while (len--) {
	crc  = (uint8_t) (crc >> 8) | (crc << 8);
	crc ^= *p++;
	crc ^= (uint8_t) (crc & 0xff) >> 4;
	crc ^= crc << 12;
	crc ^= (crc & 0xff) << 5;
      }
    }
    return crc;
  }

#endif
}

