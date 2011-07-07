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

#include "Ipv6Saa.h"

/** Provide automatic management of statically assigned addresses for
 * a single NIC.
 *
 * This component maintains a list of address prefixes and, when a
 * connected NIC comes up, assigns IPv6 addresses in the corresponding
 * subnets using the NIC's identifier.  When the NIC is taken down,
 * the addresses are released.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
generic configuration Ipv6SaaStaticC () {
  provides {
    interface Ipv6Saa;
#if TEST_IPV6_SAA_STATIC
    interface WhiteboxIpv6Saa;
#endif /* TEST_IPV6_SAA_STATIC */
  }
  uses {
    interface NetworkInterface;
  }
} implementation {

  components new Ipv6SaaStaticP(OIP_SAA_PREFIXES_PER_NIC);
  Ipv6Saa = Ipv6SaaStaticP;
  NetworkInterface = Ipv6SaaStaticP;
#if TEST_IPV6_SAA_STATIC
  WhiteboxIpv6Saa = Ipv6SaaStaticP;
#endif /* TEST_IPV6_SAA_STATIC */
  components MainC;
  MainC.SoftwareInit -> Ipv6SaaStaticP;

  components new FragmentPoolC(OIP_SAA_PREFIX_POOLSIZE_PER_NIC, OIP_SAA_PREFIXES_PER_NIC);
  Ipv6SaaStaticP.FragmentPool -> FragmentPoolC;
    
  components LocalTimeSecondC;
  Ipv6SaaStaticP.LocalTime_sec -> LocalTimeSecondC;

}
