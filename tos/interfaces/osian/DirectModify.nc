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
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Interface to properly modify bytes on flash without destroying
 * the entire erase unit.  This is best implemented on flash
 * types with smaller erase units.
 *
 * @author David Moss
 */
 
interface DirectModify {

  /**
   * Modify bytes at the given location on flash
   * @param addr The address to modify
   * @param *buf Pointer to the buffer to write to flash
   * @param len The length of data to write
   * @return SUCCESS if the bytes will be modified
   */
  command error_t modify(uint32_t addr, void *buf, uint32_t len);
  
  /**
   * Read modified bytes from flash
   * This may be different than DirectStorage.read because some media
   * types might need to split the memory in half to preserve fault tolerance
   * while modifying bytes
   * @param addr
   * @param *buf
   * @param len
   */
  command error_t read(uint32_t addr, void *buf, uint32_t len);
  
  /**
   * Ensure all recent changes are made to flash
   */
  command error_t flush();
  
  /**
   * @return TRUE if modify is supported on the given storage device
   */
  command bool isSupported();
  
  
  /**
   * Bytes have been modified on flash
   * @param addr The address modified
   * @param *buf Pointer to the buffer that was written to flash
   * @param len The amount of data from the buffer that was written
   * @param error SUCCESS if the bytes were correctly modified
   */
  event void modified(uint32_t addr, void *buf, uint32_t len, error_t error);

  /**
   * Read done
   * @param addr
   * @param *buf
   * @param len
   * @param error
   */
  event void readDone(uint32_t addr, void *buf, uint32_t len, error_t error);
  
  /**
   * All pending data has been flushed to flash
   */
  event void flushDone(error_t error);
  
}

