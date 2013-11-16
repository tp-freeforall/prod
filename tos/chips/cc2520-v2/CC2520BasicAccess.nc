/*
 * Copyright (c) 2013, Eric B. Decker
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * CC2520BasicAccess provides access to basic CC2520 structures.   This
 * includes access to registers and memory areas on the CC2520 chip.
 * Also provides access to Strobes (simple commands).
 */

interface CC2520BasicAccess {
  /*
   * strobe
   *
   * Issue simple command to the CC2520
   */

  async command uint8_t strobe(uint8_t reg);


  /*
   * readReg
   *
   * input:     reg     addr to write
   * output:    val     data read from the reg addr
   *
   * "reg" is assumed to be < 0x0100.  If < 0x040 REGRD will be used
   * otherwise MEMRD is used.
   */

  async command uint8_t readReg(uint8_t reg);


  /*
   * writeReg
   *
   * input:     reg     addr to write
   *            value   data to write
   * return:    status
   *
   * "reg" is assumed to be < 0x0100.  If < 0x040 REGWR will be used
   * otherwise MEMWR is used.
   *
   * returns cc2520 status (from returned byte on command write).
   */

  async command uint8_t writeReg(uint8_t reg, uint8_t value);


  /*
   * writeRegBlock
   *
   * input:     reg_addr        starting address
   *           *buf             pointer to src buffer
   *            count           how many bytes to write
   *
   * output:    none
   *
   * write a block of data into the register block starting at
   * address "reg".
   *
   * This can be used to write registers during initilization
   * with less overhead.pppp
   *
   * "reg" is assumed to be < 0x0100.
   */

  async command void writeRegBlock(uint8_t reg_addr, uint8_t *buf, uint8_t count);


  /*
   * readMem (MEMRD function)
   *
   * input:     mem_addr        starting address
   *           *buf             pointer to buffer
   *            count           how many bytes to read
   *
   * output:    return          status from command byte
   *
   * Reads a block of data from memory above 0x0200
   * FIFO memory is 0x0100 to 0x01ff.   General memory along
   * with local address info is above 0x0200
   */

  async command uint8_t readMem(uint16_t mem_addr, uint8_t *buf, uint8_t count);


  /*
   * writeMem (MEMWR function)
   *
   * input:     mem_addr        starting address
   *           *buf             pointer to buffer
   *            count           how many bytes to write
   *
   * output:    return          status from command byte
   *
   * Writes a block of data to memory above 0x0200
   * FIFO memory is 0x0100 to 0x01ff.   General memory along
   * with local address info is above 0x0200
   */

  async command uint8_t writeMem(uint16_t mem_addr, uint8_t *buf, uint8_t count);
}
