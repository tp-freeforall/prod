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
 * - Neither the name of the People Power Corporation nor the names of
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



#include "Average.h"

/**
 * @author David Moss
 */
module AverageP {
  provides {
    interface Init;
    interface Average[uint8_t client];
  }
}

implementation {

  
  /** The average table */
  int averageTable[uniqueCount(UQ_AVERAGE_CLIENT)][AVERAGE_WINDOW_SIZE];
  
  /** The index we're currently storing to in our average table */
  uint8_t averageIndex[uniqueCount(UQ_AVERAGE_CLIENT)];
  
  /** Number of samples taken to determine settling */
  uint8_t averageCount[uniqueCount(UQ_AVERAGE_CLIENT)];
  
  
  /***************** Init Commands ****************/
  command error_t Init.init() {
    int i;
    for(i = 0; i < uniqueCount(UQ_AVERAGE_CLIENT); i++) {
      call Average.restart[i](0);
    }
    return SUCCESS;
  }
  
  /***************** Average Commands ****************/
  /**
   * Adjust average based on new noise measurement
   * @param data noise measurement
   */
  command void Average.adjust[uint8_t client](int data) {
    atomic {
      averageTable[client][averageIndex[client]] = data;
      averageIndex[client]++;
      averageIndex[client] %= AVERAGE_WINDOW_SIZE;
      
      if(averageCount[client] <= AVERAGE_MIN_COUNT) {
        averageCount[client]++;
      }
    }
  }

  /**
   * Restart taking measurements to settle again in the future.
   */
  command void Average.restart[uint8_t client](int initialValue) {
    int i;
    
    atomic {
      for(i = 0; i < AVERAGE_WINDOW_SIZE; i++) {
        averageTable[client][i] = initialValue;
      }
    }
  }
  
  /**
   * Return current estimated average
   * @return Noise floor value
   */
  async command int Average.get[uint8_t client]() {
    int i;
    int average = 0;
    
    atomic {
      for(i = 0; i < AVERAGE_WINDOW_SIZE && i < averageCount[client]; i++) {
        average += averageTable[client][i];
      }
    }
    
    printf("Total Average before divide: %d\r\n", average);
    atomic average /= AVERAGE_WINDOW_SIZE;
    printf("Average: %d\r\n", average);
    
    return (int) average;
  }

  /**
   * Check if average estimate is considered stable (typically after
   * some number of measurements)
   * @return TRUE if average estimate considered stable, FALSE otherwise
   */
  command bool Average.settled[uint8_t client]() {
    return averageCount[client] > AVERAGE_MIN_COUNT;
  }
  

}
