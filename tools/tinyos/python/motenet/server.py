#!/usr/bin/env python

import pdb
import socket
import dspsock

port = 8081

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.bind(("", port))
sa = s.getsockname()
print "waiting on: ", sa
while 1:
    pdb.set_trace()
    data, addr = s.recvfrom(1024)
    print addr, data
    r = " ".join([repr(addr), repr(sa)]) + " : reply"
    print r
    s.sendto(r, addr)
