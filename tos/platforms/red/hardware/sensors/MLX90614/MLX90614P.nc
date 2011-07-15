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

#include <stdio.h>
#include "MLX90614.h"
#include <I2C.h>

module MLX90614P{
  provides interface MLX90614;

  uses interface I2CPacket<TI2CBasicAddr>;
}
implementation{
  
  union UReg {                                                       //Union to let us get the 16bit value from the 8bit bytes and Vicki versa
      uint8_t data[3];
      uint16_t Result;
  } RetVal;
  
  //Calculates the PEC and returns it.
  //Used to validate the data both sent and received to/from the MLX90614
  //The PEC is a CRC-8 with polynomial X8+X2+X1+1
  unsigned char PEC_calculation(unsigned char pec[]) {
    unsigned char crc[6];
    unsigned char BitPosition=47;
    unsigned char shift;
    unsigned char i;
    unsigned char j;
    unsigned char temp;

    do{
       crc[5]=0;                                                     /* Load CRC value 0x000000000107 */
       crc[4]=0;
       crc[3]=0;
       crc[2]=0;
       crc[1]=0x01;
       crc[0]=0x07;
       BitPosition=47;                                               /* Set maximum bit position at 47 */
       shift=0;
				
       //Find first 1 in the transmited message
       i=5;                                                          /* Set highest index */
       j=0;
       while((pec[i]&(0x80>>j))==0 && i>0){
         BitPosition--;
         if(j<7){
           j++;
         }
         else{
           j=0x00;
           i--;
         }
       }/*End of while */

       shift=BitPosition-8;                                          /*Get shift value for crc value*/

       //Shift crc value 
       while(shift){
         for(i=5; i<0xFF; i--){
           if((crc[i-1]&0x80) && (i>0)){
             temp=1;
           }
           else{
             temp=0;
           }
           crc[i]<<=1;
           crc[i]+=temp;
         }/*End of for*/
         shift--;
       }/*End of while*/

       //Exclusive OR between pec and crc		
       for(i=0; i<=5; i++){
         pec[i] ^=crc[i];
       }/*End of for*/

     }while(BitPosition>8);/*End of do-while*/
     return pec[0];
  } 
  
  //Read RAM/EEPROM location from MLX90614 device with address 'Address'
  //Returns 16bit register value
  async command error_t MLX90614.read(uint8_t Address,uint8_t Reg,uint16_t* data) {
    error_t error;
    uint8_t PEC;                                                     //Used to store the calculated PEC value
    unsigned char arr[6];
 
    error = call I2CPacket.write(I2C_START, Address, 1, &Reg);
    if(error==FAIL) {
      printf("I2CPacket.write Failed\n\r");                          
      return FAIL;                                                 
    }
	
    error = call I2CPacket.read(I2C_START | I2C_STOP, Address,3, RetVal.data);
    if(error==FAIL) {
      printf("I2CPacket.read Failed\n\r");                           
      return FAIL;                                                 
    }
    
    arr[5]=Address;
    arr[4]=Reg;
    arr[3]=Address; 
    arr[2]=RetVal.data[0];
    arr[1]=RetVal.data[1];
    arr[0]=0;
    PEC=PEC_calculation(arr);

    if((PEC=RetVal.data[2])) {
      *data=RetVal.Result;
      return SUCCESS;                                              //All good return SUCCESS
    }
    return FAIL;                                                   //PEC check failed return error, again bad as 0xFFFF could be valid
  }

  //Read RAM/EEPROM location from MLX90614 device with address 'Address'
  //Returns SUCCESS or FAIL
  async command error_t MLX90614.write(uint8_t Address,uint8_t Reg,uint16_t data) {
    error_t error;
    unsigned char arr[6];
     
    RetVal.Result = data;                                            //copy data into union
    error = call I2CPacket.write(I2C_START, Address, 1, &Reg);       //Select the register we want to write to
    if(error==FAIL) {
      return FAIL;
    }

    arr[4]=Address;
    arr[3]=Reg;
    arr[2]=RetVal.data[0];
    arr[1]=RetVal.data[1];
    arr[0]=0;
    RetVal.data[2]=PEC_calculation(arr);
    
    error = call I2CPacket.write(I2C_STOP, Address, 3, RetVal.data); //send the value and the PEC checksum
    if(error==FAIL) {
      return FAIL;
    }    

    return SUCCESS;
  }  
  
  //Read the status FLAGS from MLX90614 device with address 'Address' and returns 8bit value
  //Returns:
  //bit 7 6 5 4 3 2 1 0
  //    | | | | | 0 0 0
  //    | | | | Not implemented
  //    | | | INIT POR initialization routine is still ongoing, Active Low
  //    | | EE_DEAD - EEPROM double error has occurred, Active High
  //    | Not used
  //    EEBUSY - the previous write/erase EEPROM access is still in progress, Active High
  async command error_t MLX90614.status(uint8_t Address,uint8_t *Status) {
    uint16_t Result;
    error_t error;
   
    error = call MLX90614.read(Address,MLX_Status,&Result);           //Get the status of the MLX
    if(error==FAIL) {
      printf("MLX90614.read Status FAIL\n\r");
      return FAIL;
    }
    *Status=((uint8_t)Result & 0x00ff);                               //we only want the LSB 8 bits
    return(SUCCESS);
  }
 
  //Put the MLX90614 into sleep mode
  async command error_t MLX90614.sleep(uint8_t Address) {
    return (call I2CPacket.write(I2C_START | I2C_STOP, Address, 1, (uint8_t*)MLX_Sleep));
  }

  async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
  }

  async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
  }
}
