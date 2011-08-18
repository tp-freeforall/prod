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
 
//Microchip 24XX1025 EEPROM Driver
//This driver has been tested with the 24AA1025

#include <stdio.h>
#include "MC24XX1025.h"
#include <I2C.h>

module MC24XX1025P{
  provides interface MC24XX1025;

  uses interface I2CPacket<TI2CBasicAddr>;
}
implementation{

  //GetControls
  //Returns all the controls needed to read/write 
  //Params
  //address - address to start read/write operation
  //len - requested number of bytes to read/write
  //Returns in
  //Ctl - the Control byte the EEPROM requires, this selects the correct physical device and the correct block with in the device
  //blen - the number of bytes to read/write (up to boundary), max 128
  //EEAddr - two 8 bit bytes used to address the EEPROM
  void GetControls(uint32_t address,uint8_t len,uint8_t* Ctl,uint8_t* blen,uint8_t* EEAddr) {
    uint8_t Control=0x50;                                                    //Control code 1010 + Block + Chip ID 
    union {
      uint32_t address;                                                      //1 x 32 bit byte
      uint8_t add[4];                                                        //4 x 8 bit bytes
    } Adr;                                                                   //Used to split the 32bit address
    Adr.address = address;                                                   //Copy the address sent to us into the union

    if((0x0000FFFF-(address & 0x0000FFFF))+1>=128) {                         //set the number of bytes we can rewad/write up to boundary                         
      *blen=len;                                                             //set blen to len, we have space for all bytes
    } else {
      *blen=(0x0000FFFF-(address & 0x0000FFFF))+1;                           //set blen to bytes available to next boundary
    }
                                                                             //chip zero bank 0 by default
    if((address & 0x00010000) == 0x10000) Control=Control+4;                 //chip zero bank 1             
    if((address & 0x00020000) == 0x20000) Control=Control+1;                 //chip one bank 0
    if((address & 0x00030000) == 0x30000) Control=Control+5;                 //chip one bank 1
    if((address & 0x00040000) == 0x40000) Control=Control+2;                 //chip two bank 0
    if((address & 0x00050000) == 0x50000) Control=Control+6;                 //chip two bank 1
    if((address & 0x00060000) == 0x60000) Control=Control+3;                 //chip three bank 0
    if((address & 0x00070000) == 0x70000) Control=Control+7;                 //chip three bank 1
    *Ctl=Control;                                                            //Return the control byte as we've calc'ed it
	
    *EEAddr++=Adr.add[1];                                                    //The 24XX1025 expects the high byte first
    *EEAddr=Adr.add[0];                                                      //Followed by the low byte
  }

  //read
  //Reads from the EEPROM array len (128 bytes max) bytes and put the data into data
  //Returns SUCCESS/FAIL
  async command error_t MC24XX1025.read(uint32_t address, uint8_t *data, uint8_t len) {
    error_t error;
    uint8_t Control;
    uint8_t ReadLen;
    uint8_t EEAddr[2];

    if(len>128) return FAIL;

    GetControls(address,len,&Control,&ReadLen,EEAddr);                       //                        
    error = call I2CPacket.write(I2C_START, Control, 2, EEAddr);             //Set the address on the correct device
    if(error==FAIL) {
      printf("MC24XX1025.read - I2CPacket.write(0) FAIL\n\r");
      return FAIL;
    }
    //printf("GetControls address = %lx,len = %d,Control = %d,ReadLen = %d\n\r",address,len,Control,ReadLen);

    error = call I2CPacket.read(I2C_START | I2C_STOP, Control, ReadLen, data);//read the data upto the boundary (phyical or block)
    if(error==FAIL) {
      printf("MC24XX1025.read - I2CPacket.read(1) FAIL\n\r");
      return FAIL;
    }

    if((len-ReadLen)>0) {                                                    //if we have anymore data to read
      address=address+ReadLen;                                               //set the address to the address plus the bytes we have already read
      data=data+ReadLen;                                                     //set the data pointer to the correct place
      len=len-ReadLen;                                                       //set the len to the remaining number of bytes to write
      GetControls(address,len,&Control,&ReadLen,EEAddr);                     //                        
      error = call I2CPacket.write(I2C_START, Control, 2, EEAddr);           //Set the address on the correct device
      if(error==FAIL) {
        printf("MC24XX1025.read - I2CPacket.write(2) FAIL\n\r");
        return FAIL;
      }
      //printf("GetControls address = %lx,len = %d,Control = %d,ReadLen = %d\n\r",address,len,Control,ReadLen);

      error = call I2CPacket.read(I2C_START | I2C_STOP, Control, ReadLen, data);//Read the remaining bytes
      if(error==FAIL) {
        printf("MC24XX1025.read - I2CPacket.read(3) FAIL\n\r");
        return FAIL;
      }
    }
    return SUCCESS;
  }

  //write
  //Writes to the EEPROM array len (128 bytes max) bytes from data
  //Returns SUCCESS/FAIL  
  async command error_t MC24XX1025.write(uint32_t address, uint8_t *data, uint8_t len) {
    error_t error;
    uint8_t Control;
    uint8_t WriteLen;
    uint8_t EEAddr[2];
    uint8_t Msg[131];

    if(len>128) return FAIL;

    GetControls(address,len,&Control,&WriteLen,EEAddr);                    //                        
    //printf("write GetControls address = %lx,len = %d,Control = %d,WriteLen = %d\n\r",address,len,Control,WriteLen);

    memcpy(&Msg[0],&EEAddr[0],2);
    memcpy(&Msg[2],data,WriteLen);

    error = call I2CPacket.write(I2C_START | I2C_STOP, Control, WriteLen+2, Msg);        //write the data upto the boundary (phyical or block)
    if(error==FAIL) {
      printf("MC24XX1025.write - I2CPacket.write(1) FAIL\n\r");
      return FAIL;
    }

    if((len-WriteLen)>0) {                                                   //if we have anymore data
      address=address+WriteLen;                                              //set the address to the address plus the bytes we have already written
      data=data+WriteLen;                                                    //set the data pointer to the correct place
      len=len-WriteLen;                                                      //set the len to the remaining number of bytes to write
      GetControls(address,len,&Control,&WriteLen,EEAddr);                    //                        
      //printf("write GetControls address = %lx,len = %d,Control = %d,WriteLen = %d\n\r",address,len,Control,WriteLen);

      memcpy(&Msg[0],&EEAddr[0],2);
      memcpy(&Msg[2],data,WriteLen);
      error = call I2CPacket.write(I2C_START | I2C_STOP, Control, WriteLen+2, Msg);      //write the remaining bytes
      if(error==FAIL) {
        printf("MX24XX1025.write - I2CPacket.write(3) FAIL\n\r");
        return FAIL;
      }
    }

    return SUCCESS;
  }

  async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){ }

  async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){ }
}
