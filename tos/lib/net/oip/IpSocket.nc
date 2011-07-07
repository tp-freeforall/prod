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

#include <sys/socket.h>

/** Interface providing POSIX-style socket operations.
 *
 * OSIAN does not support dynamic socket creation; rather, socket
 * instances are created at build time by instantiating IpSocketC with
 * the parameters normally passed to socket(2).
 *
 * @see IpSocketMsg for sendmsg/recvmsg
 * @see IpDatagramSocket for sendto/recvfrom
 * @see IpConnectedSocket for send/recv
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface IpSocket {
  /** Return the socket id.
   *
   * Generally not useful, since OSIAN does not support dynamic
   * creation of sockets, but is used to identify non-existent sockets
   * accessed via parameterized interfaces by returning a value of
   * -1. */
  command int descriptor ();

  /** Bind the socket to a local address.
   *
   * This causes incoming packets to be filtered: if the socket is
   * bound, only packets with a destination address consistent with
   * the bound address will be delivered to the socket.
   *
   * The IP address embedded in the socket address should be a unicast
   * address bound to one of the NetworkInterface components in the
   * application.  If the protocol supports ports, a non-zero port
   * also affects packet delivery.
   *
   * @WARNING This API deviates from POSIX in that it does not include
   * the socklen_t address_len argument.  The binding is stored as a
   * reference to the provided address, rather than a copy, so the
   * length is unnecessary.  It is elided so that callers familiar
   * with POSIX who try to pass a length will receive a compile-time
   * error, come here to see why, and be reminded of this semantic
   * difference.
   *
   * @param address The adddress to which the socket should be bound.
   * Invoke with a null pointer to unbind the socket.
   *
   * @return SUCCESS if binding succeeded.  EALREADY if the socket is
   * already bound to an address.*/
  command error_t bind (const struct sockaddr* address);

  /** Determine the address to which the socket is bound.
   *
   * @WARNING This API deviates from POSIX in that it does not accept
   * arguments into which the bound address may be stored.  Rather,
   * the bound address (if any) is returned by reference.  The unused
   * POSIX arguments are elided so that callers familiar with POSIX
   * who try to pass them will receive a compile-time error, come here
   * to see why, and be reminded of this semantic difference.  It also
   * represents an unbound socket by a null sockaddr pointer, rather
   * than a sockaddr structure specifying the family-specific
   * INADDR_ANY address.
   *
   * @return The address to which the socket is bound, or a null
   * pointer if the socket is not bound. */
  command const struct sockaddr* getsockname ();
  
  /** Connect the socket to a remote address.
   *
   * The IP address embedded in the socket address should be
   * consistent with the socket domain.  No attempt is made to
   * validate this requirement.
   *
   * @WARNING This API deviates from POSIX in that it does not include
   * the socklen_t address_len argument.  The binding is stored as a
   * reference to the provided address, rather than a copy, so the
   * length is unnecessary.  It is elided so that callers familiar
   * with POSIX who try to pass a length will receive a compile-time
   * error, come here to see why, and be reminded of this
   * semantic difference.
   *
   * @param address The adddress to which the socket should be connected.
   * Invoke with a null pointer to disconnect the socket.
   *
   * @return SUCCESS if binding succeeded.  EALREADY if the socket is
   * already connected to an address.*/
  command error_t connect (const struct sockaddr* address);
  
  /** Determine the peer (remote) name to which the socket is connected.
   *
   * @WARNING This API deviates from POSIX in that it does not accept
   * arguments into which the connected address may be stored.
   * Rather, the connected address (if any) is returned by reference.
   * The unused POSIX arguments are elided so that callers familiar
   * with POSIX who try to pass them will receive a compile-time
   * error, come here to see why, and be reminded of this semantic
   * difference.  It also represents an unconnected socket by a null
   * sockaddr pointer, making it impossible to distinguish an error
   * from an unconnected socket.
   */
   command const struct sockaddr* getpeername ();

   /** Retrieve a configurable feature of a socket.
    *
    * @param level The level of the socket at which the option is
    * defined.  Generally SOL_SOCKET, IPPROTO_IPV6, or SOL_IEEE802154.
    *
    * @param option_name Identifies a particular option, such as
    * IPV6_MULTICAST_IF
    *
    * @param value Where the value of the option should be stored.
    * The underlying type is option_name-specific.
    *
    * @param option_len The number of octets available to be written at value
    *
    * @return SUCCESS generally, FAIL if the option level is
    * unrecognized, other option_name-specific values */
   command error_t getsockopt (int level,
                               int option_name,
                               void* value,
                               socklen_t* option_len);

   /** Set a configurable feature of a socket.
    *
    * @param level The level of the socket at which the option is
    * defined.  Generally SOL_SOCKET, IPPROTO_IPV6, or SOL_IEEE802154.
    *
    * @param option_name Identifies a particular option, such as
    * IPV6_MULTICAST_IF
    *
    * @param value The value to be set.  The underlying value type is
    * option_name-specific.
    *
    * @param option_len The number of octets available to be read at
    * value
    *
    * @return SUCCESS generally, FAIL if the option level is
    * unrecognized, other option_name-specific values */
   command error_t setsockopt (int level,
                               int option_name,
                               const void* value,
                               socklen_t option_len);

}
