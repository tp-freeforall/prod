/*
 * Copyright (c) 2011 Redslate Ltd.
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
 * @author Derek Baker <derek@red-slate.co.uk>
 */

//Melexis MLX90614ESF-BAA single zone IR thermometer, with on board ambient temperature sensor.
//This driver has been tested with the MLX90614ESF-BAA only but should work with the full range.

interface MLX90614{
  
  //Read RAM/EEPROM location from MLX90614 device with address 'Address' and places in data
  //Returns SUCCESS or FAIL
  async command error_t read(uint8_t Address,uint8_t Reg,uint16_t *data);

  //Write to RAM/EEPROM of MLX90614 device with address 'Address' the value of data
  //Returns SUCCESS or FAIL
  async command error_t write(uint8_t Address,uint8_t Reg,uint16_t data);  
  
  //Read the status FLAGS from MLX90614 device with address 'Address' and returns in Status 8bit value
  //Returns in Status
  //bit 7 6 5 4 3 2 1 0
  //    | | | | | 0 0 0
  //    | | | | Not implemented
  //    | | | INIT POR initialization routine is still ongoing, Active Low
  //    | | EE_DEAD - EEPROM double error has occurred, Active High
  //    | Not used
  //    EEBUSY - the previous write/erase EEPROM access is still in progress, Active High
  //Returns SUCCESS or FAIL
  async command error_t status(uint8_t Address, uint8_t *Status);
  
  //Put the MLX90614 into sleep mode
  async command error_t sleep(uint8_t Address);
}
