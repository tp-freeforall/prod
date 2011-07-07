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

#include <netinet/in.h>
#include "Ipv6Saa.h"
#include "NetworkInterface.h"

generic module Ipv6SaaStaticP (uint8_t PrefixesPerNic) {
  provides {
    interface Init;
    interface Ipv6Saa;
#if TEST_IPV6_SAA_STATIC
    interface WhiteboxIpv6Saa;
#endif /* TEST_IPV6_SAA_STATIC */
  }
  uses {
    interface NetworkInterface;
    interface FragmentPool;
    interface LocalTime<TSecond> as LocalTime_sec;
  }
} implementation {

  ipv6SaaPrefixInfo_t_* prefixes[PrefixesPerNic];

#if TEST_IPV6_SAA_STATIC
  command uint8_t WhiteboxIpv6Saa.prefixesPerNic () { return PrefixesPerNic; }
  command struct ipv6SaaPrefixInfo_t_** WhiteboxIpv6Saa.prefixes () { return prefixes; }
#endif /* TEST_IPV6_SAA_STATIC */

  command error_t Init.init ()
  {
    return SUCCESS;
  }

  event async void FragmentPool.available (unsigned int len) { }

  default event void Ipv6Saa.prefixChange (const uint8_t* prefix,
                                           uint8_t prefix_length_bits,
                                           const struct sockaddr_in6* addr,
                                           Ipv6SaaLeaseState_e lease_state) { }

  Ipv6SaaLeaseState_e stateForPrefix (const struct ipv6SaaPrefixInfo_t_* pip)
  {
    uint32_t now;
    if (~0UL == pip->preferred_timeout) {
      return SAALS_preferred;
    }
    now = call LocalTime_sec.get();
    if (now < pip->preferred_timeout) {
      return SAALS_preferred;
    }
    if (now < pip->valid_timeout) {
      return SAALS_deprecated;
    }
    return SAALS_removed;
  }

  void releaseNicAddress (struct ipv6SaaPrefixInfo_t_* pip,
                          Ipv6SaaLeaseState_e lease_state)
  {
    if (pip->address) {
      if (SAALS_UNDEFINED != lease_state) {
        signal Ipv6Saa.prefixChange(pip->prefix, pip->prefix_length_bits, pip->address, lease_state);
      }
      call NetworkInterface.releaseAddress((struct sockaddr*)pip->address);
      pip->address = 0;
    }
  }

  void assignNicAddress (struct ipv6SaaPrefixInfo_t_* pip,
                         const uint8_t* iid,
                         int8_t iid_length_bits)
  {
    union {
      struct sockaddr sa;
      struct sockaddr_in6 s6;
    } address;
    struct sockaddr_in6* s6p;
    int8_t iid_length_octets;
    const uint8_t* iide;
    uint8_t* ap;
    error_t rc;
    
    if (pip->address) {
      // Shouldn't have gotten into this function; stop before we hurt
      // somebody.
      return;
    }
    s6p = &address.s6;
    memset(s6p, 0, sizeof(*s6p));
    s6p->sin6_family = AF_INET6;
    memcpy(s6p->sin6_addr.s6_addr, pip->prefix, (pip->prefix_length_bits + 7) / 8);
    ap = s6p->sin6_addr.s6_addr + 15;
    iid_length_octets = (iid_length_bits + 7) / 8;
    iide = iid + iid_length_octets - 1;
    while (8 <= iid_length_bits) {
      *ap-- = *iide--;
      iid_length_bits -= 8;
    }
    if (0 < iid_length_bits) {
      uint16_t mask = ~((1 << iid_length_bits) - 1);
      *ap = (*ap & ~mask) | (mask & *iide);
    }
    rc = call NetworkInterface.bindAddress(&address.sa);
    pip->address = (const struct sockaddr_in6*)call NetworkInterface.locatePrefixBinding(AF_INET6, pip->prefix, pip->prefix_length_bits);
  }

  event void NetworkInterface.interfaceState (oip_nic_state_t state)
  {
    struct ipv6SaaPrefixInfo_t_** pipp = prefixes;
    struct ipv6SaaPrefixInfo_t_** pippe = prefixes + sizeof(prefixes) / sizeof(*prefixes);
    const uint8_t* iid;
    int8_t iid_length_bits;

    if (IFF_UP & state) {
      iid = call NetworkInterface.interfaceIdentifier();
      iid_length_bits = call NetworkInterface.interfaceIdentifierLength_bits();
    }
    
    for (pipp = prefixes; (pipp < pippe) && (*pipp); ++pipp) {
      struct ipv6SaaPrefixInfo_t_* pip = *pipp;
      
      if (IFF_UP & state) {
        if (128 != (pip->prefix_length_bits + iid_length_bits)) {
          continue;
        }
        if (0 == pip->address) {
          assignNicAddress(pip, iid, iid_length_bits);
        }
        if (0 != pip->address) {
          signal Ipv6Saa.prefixChange(pip->prefix, pip->prefix_length_bits, pip->address, stateForPrefix(pip));
        }
      } else {
        if (0 != pip->address) {
          releaseNicAddress(pip, SAALS_nicDown);
        }
      }
    }
  }

  /** Scan for the given prefix in the known prefix list.
   *
   * Returns a pointer into the prefixes array, or null.  If the
   * returned pointer is null, then the proposed prefix is not present
   * in the list, and there are no open spaces in the list.
   *
   * Otherwise, if the element stored at the pointer is null, the
   * prefix is not present in the list, but a new entry may be added
   * by allocating a structure and storing a pointer to it at that
   * location.
   *
   * Otherwise, the element stored at the pointer is a structure that
   * matches the prefix in length and value. */
  struct ipv6SaaPrefixInfo_t_** findPrefix_ (const uint8_t* prefix,
                                             uint8_t prefix_length_bits)
  {
    struct ipv6SaaPrefixInfo_t_** pipp = prefixes;
    struct ipv6SaaPrefixInfo_t_** pippe = prefixes + sizeof(prefixes) / sizeof(*prefixes);
    
    for (pipp = prefixes; (pipp < pippe) && (*pipp); ++pipp) {
      struct ipv6SaaPrefixInfo_t_* pip = *pipp;
      const uint8_t* candidate_pp = prefix;
      const uint8_t* existing_pp = pip->prefix;
      int8_t plb = prefix_length_bits;

      if (pip->prefix_length_bits != prefix_length_bits) {
        continue;
      }
      while (8 <= plb) {
        if (*candidate_pp++ != *existing_pp++) {
          break;
        }
        plb -= 8;
      }
      if (8 <= plb) {
        continue;
      }
      if (0 < plb) {
        uint8_t mask = ~((1 << (8 - plb)) - 1);
        if ((mask & *candidate_pp) != (mask & *existing_pp)) {
          continue;
        }
      }
      break;
    }
    return (pipp < pippe) ? pipp : 0;
  }

  command error_t Ipv6Saa.definePrefix (const uint8_t* prefix,
                                        uint8_t prefix_length_bits,
                                        uint32_t valid_lifetime,
                                        uint32_t preferred_lifetime)
  {
    struct ipv6SaaPrefixInfo_t_** pipp;
    struct ipv6SaaPrefixInfo_t_** pippe = prefixes + sizeof(prefixes)/sizeof(*prefixes);
    struct ipv6SaaPrefixInfo_t_* pip;
    uint32_t now;

    pipp = findPrefix_(prefix, prefix_length_bits);
    if (0 == pipp) {
      return ENOMEM;
    }
    pip = *pipp;
    if (! pip) {
      uint8_t* start;
      uint8_t* end;
      uint8_t record_size;
      uint8_t prefix_length_octets;
      error_t rc;

      if (0 == valid_lifetime) {
        return SUCCESS;
      }
      prefix_length_octets = (prefix_length_bits + 7) / 8;
      record_size = sizeof(*pip) + prefix_length_octets - 1;
      rc = call FragmentPool.request(&start, &end, record_size);
      if (SUCCESS != rc) {
        return rc;
      }
      rc = call FragmentPool.freeze(start, start + record_size);
      if (SUCCESS != rc) {
        (void)call FragmentPool.release(start);
        return rc;
      }
      pip = (struct ipv6SaaPrefixInfo_t_*)start;
      memset(start, 0, record_size);
      pip->prefix_length_bits = prefix_length_bits;
      memcpy(pip->prefix, prefix, prefix_length_octets);
      *pipp = pip;
    }
    if (0 == valid_lifetime) {
      releaseNicAddress(pip, SAALS_removed);
      call FragmentPool.release((uint8_t*)pip);
      while (++pipp < pippe) {
        pipp[-1] = pipp[0];
      }
      pipp[-1] = 0;
      return SUCCESS;
    }
    /* Non-infinite times store relative to the time the address is
     * defined.  (Infinite times store as infinite.  Presumably no
     * node will be powered up for the 136 years it will take for the
     * one second counter to wrap.) */
    now = call LocalTime_sec.get();
    if ((~0UL) == valid_lifetime) {
      pip->valid_timeout = valid_lifetime;
    } else {
      pip->valid_timeout = now + valid_lifetime;
    }
    if ((~0UL) == preferred_lifetime) {
      pip->preferred_timeout = preferred_lifetime;
    } else {
      pip->preferred_timeout = now + preferred_lifetime;
    }

#if (4 < __GNUC__) || ((4 == __GNUC__) && (4 < __GNUC_MINOR__)) || ((4 == __GNUC__) && (4 ==__GNUC_MINOR__) && (4 <= __GNUC_PATCHLEVEL__))
    /* This code produces a compiler bug prior to a patch introduced
     * for mspgcc4 at the time GCC 4.4.4 was supported. */
    if ((IFF_UP & (call NetworkInterface.getInterfaceState()))
        && (! pip->address)) {
      const uint8_t* iid = call NetworkInterface.interfaceIdentifier();
      int8_t iid_length_bits = call NetworkInterface.interfaceIdentifierLength_bits();
      assignNicAddress(pip, iid, iid_length_bits);
      if (pip->address) {
        signal Ipv6Saa.prefixChange(pip->prefix, pip->prefix_length_bits, pip->address, stateForPrefix(pip));
      }
    }
#endif
    return SUCCESS;
  }
  
  
}
