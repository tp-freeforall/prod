/*
 * Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
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
 * Generic network stack interface for Ieee154-based applications.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

configuration Ieee154MessageC {
  provides {
    interface SplitControl;

    interface Ieee154Send;
    interface Receive as Ieee154Receive;

    interface Packet;
    interface Ieee154Packet;

    interface MessageLqi;
    interface MessageRssi;

    interface PacketAcknowledgements; /* @TODO@ implement */
    interface LowPowerListening;
    interface Resource;
 }
} implementation {
  components Rf1aIeee154MessageC as MsgC;
  SplitControl = MsgC;
  Ieee154Send = MsgC;
  Ieee154Receive = MsgC;
  Packet = MsgC;
  Ieee154Packet = MsgC;
  PacketAcknowledgements = MsgC;
  LowPowerListening = MsgC;
  Resource = MsgC;

  MessageLqi = MsgC;
  MessageRssi = MsgC;

  components RadioRssiC;
  RadioRssiC.Rf1aPhysical -> MsgC;
}

/* 
 * Local Variables:
 * mode: c
 * End:
 */
