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
 * Exponentially weighted moving averages
 * 
 * @author Philip Buonadonna
 * @author Jaein Jeong
 * @author Joe Polastre
 * @author David Gay
 * @author Mark Hays
 * @author David Moss
 */
  
#include "Ewma.h"

module EwmaP {
  provides {
    interface Init;
    interface Ewma[uint8_t client];
  }
}

implementation {

  /** The threshold before we see a clear channel */
  int clearThreshold[uniqueCount(UQ_EWMA_CLIENT)];
  
  /** The ewma table */
  int ewmaTable[uniqueCount(UQ_EWMA_CLIENT)][EWMA_TABLE_SIZE];
  
  /** The index we're currently storing to in our ewma table */
  uint8_t  ewmaIndex[uniqueCount(UQ_EWMA_CLIENT)];
  
  /** Number of samples taken to determine settling */
  int  ewmaCount[uniqueCount(UQ_EWMA_CLIENT)];
  
  
  /***************** Init Commands ****************/
  command error_t Init.init() {
    int i;

    for(i = 0; i < uniqueCount(UQ_EWMA_CLIENT); i++) {
      call Ewma.restart[i](EWMA_INITIAL_THRESHOLD);
    }
    
    return SUCCESS;
  }

  /***************** Ewma Commands ****************/
  command void Ewma.adjust[uint8_t client](int data) {
    int buf[EWMA_TABLE_SIZE];
    int cur;
    int med;
    int upd;
    int tmp;
    uint8_t  i;

    // add data to table
    ewmaTable[client][ewmaIndex[client]++] = data;
    
    if (ewmaIndex[client] >= EWMA_TABLE_SIZE) {
      ewmaIndex[client] = 0;
    }
    
    // settled?
    if (ewmaCount[client] <= EWMA_MIN_COUNT) {
      ewmaCount[client]++;
    }

    // compute median using... (partial) bubble sort!
    memcpy(buf, ewmaTable[client], sizeof(buf));
    for (i = 0; i <= EWMA_TABLE_SIZE >> 1; i++) { // only need to sort bottom half
      uint8_t  mp = i, j;
      int mv = buf[i], v;

      for (j = i + 1; j < EWMA_TABLE_SIZE; j++) {
        if ((v = buf[j]) < mv) {
          mv = v;
          mp = j;
        }
      }
      
      if (mp != i) {
        v       = buf[i];
        buf[i]  = mv;
        buf[mp] = v;
      }
    }
    
    med = buf[EWMA_TABLE_SIZE >> 1];

    // Do an exponentially weighted moving average (EWMA) update
    atomic cur = clearThreshold[client];
    tmp  = ((uint32_t) cur) * ((uint32_t) EWMA_NUMERATOR);
    tmp += ((uint32_t) med) * ((uint32_t) (EWMA_DENOMINATOR - EWMA_NUMERATOR));
    tmp /= (uint32_t) EWMA_DENOMINATOR;
    upd  = tmp;
    
    // if the division truncated the result, give it a kick
    if ((upd == cur) && (med > upd)) {
      upd++;
    }

    // and save it
    atomic clearThreshold[client] = upd;
  }
  
  command void Ewma.restart[uint8_t client](int initialValue) {
    int i;

    clearThreshold[client] = initialValue;
    ewmaCount[client] = 0;
    ewmaIndex[client] = 0;
    for (i = 0; i < EWMA_TABLE_SIZE; i++) {
      ewmaTable[client][i] = initialValue;
    }
  }
  
  async command int Ewma.get[uint8_t client]() {
    return clearThreshold[client];
  }
  
  command bool Ewma.settled[uint8_t client]() {
    return ewmaCount[client] >= EWMA_MIN_COUNT;
  }
  
}
