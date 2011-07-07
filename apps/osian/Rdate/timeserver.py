#!/usr/bin/python

import time

import socket
import select
import binascii
import struct

port = 1037

sock_args = (socket.AF_INET6, socket.SOCK_DGRAM, socket.IPPROTO_UDP)

rv = socket.getaddrinfo('host.ppp.osian', port, *sock_args)
if_sockaddr = rv[0][4]
if_addr = if_sockaddr[0]
if_addr_packed = socket.inet_pton(socket.AF_INET6, if_addr)

rv = socket.getaddrinfo('ff02::1', port, *sock_args)
mc_sockaddr = rv[0][4]
mc_addr = mc_sockaddr[0]
mc_addr_packed = socket.inet_pton(socket.AF_INET6, mc_addr)

sfd = socket.socket(*sock_args)

if_index = if_sockaddr[3]
if 0 == if_index:
    # Interface address did not include scope id.  Try to find it.
    # NB: This probably only works on Linux.
    if_hexstr = binascii.hexlify(if_addr_packed)
    for if6 in file('/proc/net/if_inet6').readlines():
        if if6.startswith(if_hexstr):
            if_index = int(if6.split()[1], 16)
            if_sockaddr = if_sockaddr[:3] + (if_index,)
            break
if 0 == if_index:
    raise Exception('Unable to identify scope_id for address %s' % (if_sockaddr,))

if_index_packed = struct.pack('I', if_index)
sfd.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_MULTICAST_IF, if_index_packed)

mc_sockaddr = mc_sockaddr[:3] + (if_index,)
mreq_packed = mc_addr_packed + if_index_packed
sfd.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_JOIN_GROUP, mreq_packed)

bind_sockaddr = ('::',) + mc_sockaddr[1:]
sfd.bind(bind_sockaddr)

# Offset of POSIX epoch (1970-01-01T00:00:00Z) from RFC868 epoch
# (1900-01-01T00:00:00Z)
RFC868_EPOCH_OFFSET = 2208988800

poller = select.poll()
poller.register(sfd, select.POLLIN)
while True:
    rc = poller.poll()
    if rc:
        (request, sender) = sfd.recvfrom(16384)
        now_rfc868 = int(0.5 + time.time()) + RFC868_EPOCH_OFFSET
        print 'At %u %s sent %d octets: %s' % (now_rfc868, sender[0], len(request), binascii.hexlify(request))
        response = struct.pack('!IH', now_rfc868, 0)
        sfd.sendto(response, sender)
