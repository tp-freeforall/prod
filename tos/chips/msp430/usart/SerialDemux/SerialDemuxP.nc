/**
 * Copyright (c) 2013 Eric B. Decker
 * Copyright (c) 2008-2010 Eric B. Decker
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
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include "serial_demux.h"

module SerialDemuxP {
  provides {
    interface UartByte                as SerialClientUartByte[uint8_t client_id];
    interface UartStream              as SerialClientUartStream[uint8_t client_id];
    interface ResourceDefaultOwner    as SerialDefOwnerClient[uint8_t client_id];
    interface ResourceDefaultOwnerMux as MuxControl;
    interface ResourceDefaultOwnerInfo;
  }

  uses {
    interface ResourceDefaultOwner;
    interface UartByte;
    interface UartStream;
    interface Panic;
  }
}

implementation {
  norace uint8_t serial_defowner = 0;

  void sdm_warn(uint8_t where, uint16_t p) {
    call Panic.warn(PANIC_COMM, where, p, 0, 0, 0);
  }

  async command error_t SerialClientUartByte.send[ uint8_t client_id ]( uint8_t data ) {
    if (serial_defowner != client_id) {
      sdm_warn(1, client_id);
      return FAIL;
    }
    return call UartByte.send(data);
  }

  async command error_t SerialClientUartByte.sendAvail[ uint8_t client_id ]() {
    if (serial_defowner != client_id) {
      sdm_warn(1, client_id);
      return FALSE;
    }
    return call UartByte.sendAvail();
  }

  async command error_t SerialClientUartByte.receive[ uint8_t client_id ]( uint8_t* byte, uint8_t timeout ) {
    if (serial_defowner != client_id) {
      sdm_warn(2, client_id);
      return FAIL;
    }
    return call UartByte.receive(byte, timeout);
  }

  async command error_t SerialClientUartByte.receiveAvail[ uint8_t client_id ]() {
    if (serial_defowner != client_id) {
      sdm_warn(2, client_id);
      return FALSE;
    }
    return call UartByte.receiveAvail();
  }

  async event void UartStream.receivedByte(uint8_t byte) {
    signal SerialClientUartStream.receivedByte[serial_defowner](byte);
  }
  
  async command error_t SerialClientUartStream.enableReceiveInterrupt[ uint8_t client_id ]() {
    if (serial_defowner != client_id) {
      sdm_warn(3, client_id);
      return FAIL;
    }
    return call UartStream.enableReceiveInterrupt();
  }
  
  async command error_t SerialClientUartStream.disableReceiveInterrupt[ uint8_t client_id ]() {
    if (serial_defowner != client_id) {
      sdm_warn(4, client_id);
      return FAIL;
    }
    return call UartStream.disableReceiveInterrupt();
  }

  async command error_t SerialClientUartStream.receive[ uint8_t client_id ]( uint8_t* buf, uint16_t len ) {
    if (serial_defowner != client_id) {
      sdm_warn(5, client_id);
      return FAIL;
    }
    return call UartStream.receive(buf, len);
  }

  async event void UartStream.receiveDone(uint8_t* buf, uint16_t len, error_t error) {
    signal SerialClientUartStream.receiveDone[serial_defowner](buf, len, error);
  }
  
  async command error_t SerialClientUartStream.send[ uint8_t client_id ]( uint8_t* buf, uint16_t len ) {
    if (serial_defowner != client_id) {
      sdm_warn(6, client_id);
      return FAIL;
    }
    return call UartStream.send(buf, len);
  }

  async event void UartStream.sendDone(uint8_t* buf, uint16_t len, error_t error) {
    signal SerialClientUartStream.sendDone[serial_defowner](buf, len, error);
  }

  async command error_t MuxControl.set_mux(uint8_t owner) {
    serial_defowner = owner;
    return SUCCESS;
  }

  async command uint8_t MuxControl.get_mux() {
    return serial_defowner;
  }

  async command error_t SerialDefOwnerClient.release[uint8_t client_id]() {
    if (serial_defowner == client_id)
      return call ResourceDefaultOwner.release();
    sdm_warn(7, client_id);
    return FAIL;
  }

  async command bool SerialDefOwnerClient.isOwner[uint8_t client_id]() {
    if (serial_defowner != client_id)
      return FALSE;
    return call ResourceDefaultOwner.isOwner();
  }

  async event void ResourceDefaultOwner.granted() {
    signal SerialDefOwnerClient.granted[serial_defowner]();
  }

  async event void ResourceDefaultOwner.requested() {
    signal SerialDefOwnerClient.requested[serial_defowner]();
  }

  async event void ResourceDefaultOwner.immediateRequested() {
    signal SerialDefOwnerClient.immediateRequested[serial_defowner]();
  }

  async command bool ResourceDefaultOwnerInfo.inUse() {
    return serial_defowner != 0;
  }

  default async event void SerialDefOwnerClient.granted[uint8_t client_id]() {}
  default async event void SerialDefOwnerClient.requested[uint8_t client_id]() {}

  default async event void SerialClientUartStream.sendDone[ uint8_t client_id ](uint8_t* buf, uint16_t len, error_t error) {}
  default async event void SerialClientUartStream.receivedByte[ uint8_t client_id ](uint8_t byte) {}
  default async event void SerialClientUartStream.receiveDone[ uint8_t client_id ]( uint8_t* buf, uint16_t len, error_t error ) {}
}
