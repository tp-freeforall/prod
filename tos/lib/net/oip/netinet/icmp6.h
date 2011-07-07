/* Copyright (c) 2010 People Power Co.
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
 *
 */

#ifndef OSIAN_OIP_NETINET_ICMP6_H_
#define OSIAN_OIP_NETINET_ICMP6_H_

/** ICMP6 message types and codes, per RFC4443. */
enum {
  ICMP6_DST_UNREACH = 1,
  ICMP6_DST_UNREACH_NOROUTE = 0,
  ICMP6_DST_UNREACH_ADMIN = 1,
  ICMP6_DST_UNREACH_BEYONDSCOPE = 2,
  ICMP6_DST_UNREACH_ADDR = 3,
  ICMP6_DST_UNREACH_NOPORT = 4,
  ICMP6_DST_UNREACH_SAGRESS = 5,
  ICMP6_DST_UNREACH_REJROUTE = 6,

  ICMP6_PACKET_TOO_BIG = 2,

  ICMP6_TIME_EXCEEDED = 3,
  ICMP6_TIME_EXCEEDED_TRANSIT = 0,
  ICMP6_TIME_EXCEEDED_REASSEMBLY = 1,

  ICMP6_PARAM_PROB = 4,
  ICMP6_PARAM_PROB_HEADER = 0,
  ICMP6_PARAM_PROB_NEXTHEADER = 1,
  ICMP6_PARAM_PROB_OPTION = 2,

  ICMP6_ECHO_REQUEST = 128,
  ICMP6_ECHO_REPLY = 129,

};

struct icmp6_hdr {
  uint8_t icmp6_type;
  uint8_t icmp6_code;
  uint16_t icmp6_cksum;
  union {
    uint32_t icmp6_un_data32[1];
    uint16_t icmp6_un_data16[2];
    uint8_t icmp6_un_data8[4];
  } icmp6_dataun;
#define icmp6_data32 icmp6_dataun.icmp6_un_data32
#define icmp6_data16 icmp6_dataun.icmp6_un_data16
#define icmp6_data8 icmp6_dataun.icmp6_un_data8
};

#endif /* OSIAN_OIP_NETINET_ICMP6_H_ */
