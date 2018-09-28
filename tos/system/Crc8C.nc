/* Copyright (c) 2018, Eric B. Decker, Daniel J. Multbie
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
 */

/**
 * CRC-8 implementation of CRC-8-SAE-J1850 (OBD crc-8).  See
 * http://www.sunshine2k.de/articles/coding/crc/understanding_crc.html#ch4
 *
 * @author Eric B. Decker <cire831@gmail.com>
 * @author Daniel J. Maltbie <dmaltbie@dalome.com>
 */

module Crc8C {
  provides interface Crc<uint8_t> as Crc8;
}

implementation {

  const uint8_t crcTable[] = {0x00, 0x07, 0x0e, 0x09, 0x1c, 0x1b, 0x12, 0x15, 0x38,
                              0x3f, 0x36, 0x31, 0x24, 0x23, 0x2a, 0x2d, 0x70, 0x77,
                              0x7e, 0x79, 0x6c, 0x6b, 0x62, 0x65, 0x48, 0x4f, 0x46,
                              0x41, 0x54, 0x53, 0x5a, 0x5d, 0xe0, 0xe7, 0xee, 0xe9,
                              0xfc, 0xfb, 0xf2, 0xf5, 0xd8, 0xdf, 0xd6, 0xd1, 0xc4,
                              0xc3, 0xca, 0xcd, 0x90, 0x97, 0x9e, 0x99, 0x8c, 0x8b,
                              0x82, 0x85, 0xa8, 0xaf, 0xa6, 0xa1, 0xb4, 0xb3, 0xba,
                              0xbd, 0xc7, 0xc0, 0xc9, 0xce, 0xdb, 0xdc, 0xd5, 0xd2,
                              0xff, 0xf8, 0xf1, 0xf6, 0xe3, 0xe4, 0xed, 0xea, 0xb7,
                              0xb0, 0xb9, 0xbe, 0xab, 0xac, 0xa5, 0xa2, 0x8f, 0x88,
                              0x81, 0x86, 0x93, 0x94, 0x9d, 0x9a, 0x27, 0x20, 0x29,
                              0x2e, 0x3b, 0x3c, 0x35, 0x32, 0x1f, 0x18, 0x11, 0x16,
                              0x03, 0x04, 0x0d, 0x0a, 0x57, 0x50, 0x59, 0x5e, 0x4b,
                              0x4c, 0x45, 0x42, 0x6f, 0x68, 0x61, 0x66, 0x73, 0x74,
                              0x7d, 0x7a, 0x89, 0x8e, 0x87, 0x80, 0x95, 0x92, 0x9b,
                              0x9c, 0xb1, 0xb6, 0xbf, 0xb8, 0xad, 0xaa, 0xa3, 0xa4,
                              0xf9, 0xfe, 0xf7, 0xf0, 0xe5, 0xe2, 0xeb, 0xec, 0xc1,
                              0xc6, 0xcf, 0xc8, 0xdd, 0xda, 0xd3, 0xd4, 0x69, 0x6e,
                              0x67, 0x60, 0x75, 0x72, 0x7b, 0x7c, 0x51, 0x56, 0x5f,
                              0x58, 0x4d, 0x4a, 0x43, 0x44, 0x19, 0x1e, 0x17, 0x10,
                              0x05, 0x02, 0x0b, 0x0c, 0x21, 0x26, 0x2f, 0x28, 0x3d,
                              0x3a, 0x33, 0x34, 0x4e, 0x49, 0x40, 0x47, 0x52, 0x55,
                              0x5c, 0x5b, 0x76, 0x71, 0x78, 0x7f, 0x6a, 0x6d, 0x64,
                              0x63, 0x3e, 0x39, 0x30, 0x37, 0x22, 0x25, 0x2c, 0x2b,
                              0x06, 0x01, 0x08, 0x0f, 0x1a, 0x1d, 0x14, 0x13, 0xae,
                              0xa9, 0xa0, 0xa7, 0xb2, 0xb5, 0xbc, 0xbb, 0x96, 0x91,
                              0x98, 0x9f, 0x8a, 0x8d, 0x84, 0x83, 0xde, 0xd9, 0xd0,
                              0xd7, 0xc2, 0xc5, 0xcc, 0xcb, 0xe6, 0xe1, 0xe8, 0xef,
                              0xfa, 0xfd, 0xf4, 0xf3};

  /*
   * xor in input byte to current crc
   * get next crc value from the table
   */
  uint8_t Compute_CRC8(uint8_t start, uint8_t * bytes, uint8_t blen) {
    uint8_t crc = start;
    uint8_t data;
    int     x;

    for (x = 0; x < blen; x++) {
      data = bytes[x] ^ crc;
      crc  = crcTable[data];
    }
    return crc;
  }

#ifdef notdef
  static void CalulateTable_CRC8() {
    const byte generator = 0x1D;

    crctable = new byte[256];
    /* iterate over all byte values 0 - 255 */
    for (int divident = 0; divident < 256; divident++) {
      byte currByte = (byte)divident;

      for (byte bit = 0; bit < 8; bit++) {
        if ((currByte & 0x80) != 0) {
          currByte <<= 1;
          currByte ^= generator;
        } else
          currByte <<= 1;
      }
      /* store CRC value in lookup table */
      crctable[divident] = currByte;
    }
  }
#endif

  /**
   * Compute the CRC-8 value of a byte array.
   *
   * @param   buf A pointer to the buffer over which to compute CRC.
   * @param   len The length of the buffer over which to compute CRC.
   * @return  The CRC-16 value.
   */
  async command uint8_t Crc8.crc(uint8_t *buf, uint8_t len) {
    return Compute_CRC8(0, buf, len);
  }

  /**
   * Compute the CRC-8 value using a given seed.  Used to compute CRC's
   * of discontiguous data.
   *
   * @param startCrc An initial CRC value to begin with
   * @param buf A pointer to a buffer of data
   * @param len The length of the buffer
   * @return The CRC-8 value.
   */
  async command uint8_t Crc8.seededCrc(uint8_t startCrc, uint8_t *buf, uint8_t len) {
    return Compute_CRC8(startCrc, buf, len);
  }
}
