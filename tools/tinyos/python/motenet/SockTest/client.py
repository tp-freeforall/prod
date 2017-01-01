#!/usr/bin/env python3

import pdb
import socket
import sys

HOST = '192.168.1.7'                #'fe80::f129:4d8a:2a6e:7a3d'
UDPSAM_BASE = 0x2e00                # where the types start.  (11776 (0x2e00) - 12031 (0x2eff))
PORT = UDPSAM_BASE + 0xa1           # MM Ctrl port (161, A1)

s = None

print('Starting socket')

res = socket.getaddrinfo(HOST, PORT, socket.AF_UNSPEC, socket.SOCK_DGRAM)
print(res)
for r in res:
    af, socktype, proto, canonname, sa = r
    print(r)
#    pdb.set_trace()
    try:
        s = socket.socket(af, socktype, proto)
    except socket.error as msg:
        print("socket_socket error: {}".format(msg))
        s = None
        continue
    try:
        s.connect(sa)
    except socket.error as msg:
        s.close()
        s = None
        continue
    break

if s is None:
    print('could not open socket')
    sys.exit(1)

s.send(b'Hello Carl!')
print(s.getsockname())
data, ra = s.recvfrom(1024)
s.close()
print('Received', repr(data))
