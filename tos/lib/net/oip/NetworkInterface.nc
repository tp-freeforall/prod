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

#include "NetworkInterface.h"
#include <net/if.h>
#include <sys/socket.h>

/** An OIP network interface connects a specific link layer to the IP
 * infrastructure.  Associated with that interface are a set of
 * addresses by which the interface can be, um, addressed.  This
 * TinyOS interface supports address-related network interface
 * behavior.
 *
 * The number of addresses that can be bound to any NIC is determined
 * by the value of the OIP_ADDRESSES_PER_NIC preprocessor symbol.  The
 * definition and default setting for this symbol is in the <net/if.h>
 * header file.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com> */
interface NetworkInterface {
  /** Return the identifier for the network interface.
   *
   * This is an integer value starting at one.  A value based on it is
   * used for IPv6 address scope definition.
   *
   * @note When used as a parameter, e.g. to a parameterized
   * interface, a formal parameter specified as "nic_id1" in the
   * declaration conforms to this number.  A value specified as
   * "nic_id0" is based at zero, and suitable for use accessing
   * array-style data structures.
   *
   * @return A positive network identifier; -1 if the NetworkInterface
   * is not present.
   */
  command oip_network_id_t id ();

  /** Associate a given address with the network as its link-level address.
   *
   * @param addr The address to use as the link-level address.  Pass a
   * null pointer to dissociate the network from its link level
   * address.
   *
   * @return EALREADY if attempt to assign an address with one already
   * assigned; SUCCESS otherwise. */
  command error_t setLinkAddress (const struct sockaddr* addr);

  /** Return the link-level address for the interface by a previous
   * setLinkAddress command.
   *
   * @return Link level address, or null pointer if no link level
   * address assigned. */
  command const struct sockaddr* getLinkAddress ();

  /** Return an array of all addresses bound to the interface.
   *
   * @param addrsp Address of a pointer into which may be stored a
   * pointer to a sequence of pointers to addresses that are bound
   * to the interface.  (If you don't understand that, please don't
   * use this function.)
   *
   * @return The number of addresses bound to the interface (this is
   * the limit on indexing off the pointer value stored in *addrsp).
   * A negative value indicates an invalid addrsp parameter.
   */
  command int boundAddresses (const struct sockaddr* const** addrsp);

  /** Bind the given address to the interface.
   *
   * Each interface can hold only a limited number of addresses.  No
   * attempt is made to sort these, or to avoid duplicates.
   *
   * @param addr Address to be bound.  The address is stored by value;
   * no reference to this parameter is retained.
   *
   * @return SUCCESS if address was bound; ENOMEM if all available
   * address slots have been used. */
  command error_t bindAddress (const struct sockaddr* addr);

  /** Dissociate the binding between this interface and the address.
   *
   * @param addr An address to be removed from the list of bound
   * addresses.
   *
   * @return EINVAL if addr is not bound to this interface.  SUCCESS
   * otherwise. */
  command error_t releaseAddress (const struct sockaddr* addr);

  /** Locate a bound address with a given prefix in the given family.
   *
   * @param address_family The address family to which an acceptable
   * address must belong.
   *
   * @param prefix The bit sequence against which the address is to be
   * compared.
   *
   * @param prefix_length_bits The number of initial bits to which the
   * prefix must match the address for success
   *
   * @return a pointer to the first bound address that matches the given prefix.
   * If no bound addresses match the prefix, returns a null pointer.
   */
  command const struct sockaddr* locatePrefixBinding (sa_family_t address_family,
                                                      const uint8_t* prefix,
                                                      unsigned int prefix_length_bits);

  /** Return an array of all groups the interface has joined.
   *
   * @param addrsp Address of a pointer into which may be stored a
   * pointer to a sequence of pointers to groups that are joined
   * to the interface.  (If you don't understand that, please don't
   * use this function.)
   *
   * @return The number of groups bound to the interface (this is
   * the limit on indexing off the pointer value stored in *addrsp).
   * A negative value indicates an invalid addrsp parameter.
   */
  command int joinedGroups (const struct sockaddr* const** addrsp);

  /** Join the multicast group described by the given address.
   *
   * Each interface can join only a limited number of groups.  No
   * attempt is made to sort these, or to avoid duplicates.  It is the
   * callers responsibility to ensure that the address represents a
   * multicast group in its family.
   *
   * @note If multiple sockets join the same group on the same
   * interface, the corresponding address will be stored multiple
   * times.  This is intentional; the situation should rarely if ever
   * arise, and replicating the addresses eliminates the need to
   * reference count them in the interface.
   *
   * @param addr Address to be bound.  The joined address is stored by
   * value; no reference to the passed address is retained.
   *
   * @return SUCCESS if address was bound; ENOMEM if all available
   * address slots have been used. */
  command error_t joinGroup (const struct sockaddr* addr);

  /** Cause the interface to leave the given group.
   *
   * @param addr A multicast group to be removed from the list of
   * joined groups.
   *
   * @return EINVAL if this interface is not a group member.  SUCCESS
   * otherwise. */
  command error_t leaveGroup (const struct sockaddr* addr);

  /** Determine whether the interface should accept packets destined
   * for the given address.
   *
   * This is delegated to AddressFamily.acceptDeliveryTo().
   *
   * @param daddr The destination address of some packet
   *
   * @return TRUE iff packets to the provided address should be
   * accepted on this interface. */
  command int acceptDeliveryTo (const struct sockaddr* daddr);

  /** Forward to the paired NetworkLinkInterface storeLinkHeader
   * command. */
  command int storeLinkHeader (const struct sockaddr* saddr,
                               const struct sockaddr* daddr,
                               unsigned int len,
                               uint8_t* dst);

  /** Forward to the paired NetworkLinkInterface transmit
   * command. */
  command error_t transmit (const void* message,
                            unsigned int len);

  /** Delegate to the paired NetworkInterfaceIdentifier */
  command const uint8_t* interfaceIdentifier ();
  
  /** Delegate to the paired NetworkInterfaceIdentifier */
  command uint8_t interfaceIdentifierLength_bits ();

  /** Return the current state of the interface.
   *
   * @return A set of IFF_* flags encoded as bits in an integer
   */
  command oip_nic_state_t getInterfaceState ();

  /** Set the interface state.
   *
   * Setting the interface state with this command causes the
   * interfaceState() event to be raised after the state is updated.
   *
   * Note: If you aren't implementing the interface, please don't call
   * this method.
   *
   * @param state The new state for the interface.
   */
  command void setInterfaceState (oip_nic_state_t state);

  /** Raised upon an update to the interface state.
   *
   * Monitor this event to determine when an interface is brought up
   * and taken down.
   *
   * The value in the state may not incorporate a change from the
   * previous state.
   *
   * @note For some interfaces, the state may be initialized during
   * software initialization.  Generall IFF_UP will not be part of
   * this state.  Handlers of this event should be careful not to do
   * anything inappropriate in this situation.
   *
   * @param state the current state of the interface.
   */
  event void interfaceState (oip_nic_state_t state);

  /** Retrieve metadata for the last message received on the interface.
   *
   * The returned value points to a link-specific structure.  The
   * caller must be aware of the underlying link used by the network
   * interface in order to interpret its value correctly.  The pointer
   * is valid only until the invoking task releases control; it should
   * not be assumed to be correct for subsequent messages.
   */
  command const void* rxMetadata ();

}
