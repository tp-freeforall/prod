# Monitor MulticastRadioNet update messages when BridgePppRadio is running.
#
import socket
import select
import binascii
import struct

port = 50386

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

payload_layout = '<8sH'

poller = select.poll()
poller.register(sfd, select.POLLIN)
while True:
    rc = poller.poll()
    if rc:
        (payload, sender) = sfd.recvfrom(16384)
        (eui64, seqno) = struct.unpack(payload_layout, payload)
        print 'seqno %d eui %s from %s' % (seqno, binascii.hexlify(eui64), sender[0])

    
