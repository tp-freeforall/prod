# Monitor UnicastRadioNet update messages when BridgePppRadio is running.
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

sfd = socket.socket(*sock_args)
sfd.bind(('::', port, 0, 0))

payload_layout = '<8sH'

poller = select.poll()
poller.register(sfd, select.POLLIN)
counter = 0
while True:
    rc = poller.poll()
    if rc:
        (payload, sender) = sfd.recvfrom(16384)
        (eui64, seqno) = struct.unpack(payload_layout, payload)
        print 'seqno %d eui %s from %s' % (seqno, binascii.hexlify(eui64), sender[0])
        counter += 1
        sfd.sendto(struct.pack(payload_layout, '12345678', counter), sender)
    
