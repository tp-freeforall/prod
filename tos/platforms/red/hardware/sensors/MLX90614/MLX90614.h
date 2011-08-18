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

#ifndef MLX90614_H
#define MLX90614_H

//EEPROM Registers - all 16bit

#define MLX_TOmax     0x20                              //R/W - Object Temperature seen via the IR sensor Max, see datasheet 
#define MLX_TOmin     0x21                              //R/W - Object Temperature seen via the IR sensor Min, see datasheet
#define MLX_PWMCTRL   0x22                              //R/W - Pulse width modulation control, not used here, we are I2C
#define MLX_TaRnge    0x23                              //R/W - Temperature range, see datasheet
#define MLX_EMcc      0x24                              //R/W - Emissivity correction coefficient, see datasheet
#define MLX_Conf1     0x25                              //R/W - config register one, see datasheet
#define MLX_SMBusAddr 0x2E                              //R/W - SMBus address default is 0x005A
#define MLX_IDNum1    0x3C                              //R - Unique id number 1/4
#define MLX_IDNum2    0x3D                              //R - Unique id number 2/4
#define MLX_IDNum3    0x3E                              //R - Unique id number 3/4
#define MLX_IDNum4    0x3F                              //R - Unique id number 4/4

//RAM Registers - all Read only - all 16bit

#define MLX_RawIR1    0x04                              //Raw temperature reading from object sensor one
#define MLX_RawIR2    0x05                              //Raw temperature reading from object sensor two
#define MLX_Ta        0x06                              //Temperature of the ambient sendor (in kelvin)
#define MLX_To1       0x07                              //Temperature of the object sensor one (in kelvin)
#define MLX_To2       0x08                              //Temperature of the object sensor two (in kelvin)

//Commands
#define MLX_Status    0xF0                              //Read Status register
#define MLX_Sleep     0xFF                              //Enter Sleep mode

//MLX90614 Status FLAGS
enum {
  MLX_EEBUSY = 7,
  MLX_EE_DEAD = 5,
  MLX_INIT = 4,
};

#define MLX_Default_Addr  0x005A

#endif /* MLX90614_H */
