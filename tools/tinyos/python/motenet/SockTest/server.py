#!/usr/bin/env python3

import pdb
import socket
import sys

UDPSAM_BASE = 0x2e00                # where the types start.  (11776 (0x2e00) - 12031 (0x2eff))
PORT = UDPSAM_BASE + 0xa1           # MM Ctrl port (161, A1)

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    s.bind(('', PORT))
except socket.error as err:
    print("Couldn't be a udp server on port %d : %s" % (PORT, err))
    raise SystemExit

while True:
    datagram = s.recv(1024)
    if not datagram:
        break
    # do something
s.close()
