/*
 * Copyright (c) 2017 Eric B. Decker
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
 * SpiReg: interface to a simple flavor of register based spi hardware.
 * For example the ST Micro LIS2DH12 Accelerometer is programmed using
 * a number of registers.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * chip follows the following SPI protocol:
 *
 * o Assert CS
 * o first byte is address.
 *   An R bit (when set do a read, else write)
 *   The M bit (multiple), auto increment register
 *   6 bits of address, the register being accessed.
 * o next byte is read or write
 * o deassert CS
 *
 * The actual underlying driver and hardware implementation determines
 * how this all works.  The details won't effect this interface.
 */

interface SpiReg {
  /*
   * read               read one or more bytes from a single address.
   * read_multiple      read one or more bytes from a sequence of registers.
   *
   * input:	reg_addr starting register address
   *		*buf	 pointer to where to store incoming bytes
   *            len      how many bytes to read.
   */
  command void read(uint8_t reg_addr, uint8_t *buf, uint8_t len);
  command void read_multiple(uint8_t reg_addr, uint8_t *buf,
                                   uint8_t len);

  /*
   * write              write one or more bytes from a single address.
   * write_multiple     write one or more bytes from a sequence of registers.
   *
   * input:	reg_addr starting register address
   *		*buf     pointer to where to stash incoming bytes
   *            len      how many bytes to write.
   */
  command void write(uint8_t reg_addr, uint8_t *buf, uint8_t len);
  command void write_multiple(uint8_t reg_addr, uint8_t *buf,
                                    uint8_t len);
}
