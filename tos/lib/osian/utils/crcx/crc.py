/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
 * All rights reserved.
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Mark Hays
 */
 
########################################################################
### crc.py -- dinking around with CRC algorithms
###
### see Crc32P.nc for reference
###

def crc16_(crc, b):
    for i in xrange(8):
        f = (b & 0x80) << 8
        f = ((crc ^ f) & 0x8000) and 0x1021 or 0
        crc = ((crc << 1) ^ f) & 0xffff
        b = b << 1
    return crc

T = [crc16_(0, 1 << i) for i in xrange(8)]

def bin(x, N=32):
    l = []
    for i in xrange(N):
        if i and not i & 7:
            l.insert(0, "_")
        l.insert(0, (x & 1) and "1" or "0")
        x >>= 1
    l.insert(0, "0b_")
    return "".join(l)

def dT(t, N=32):
    for i in xrange(len(t)):
        j = 1 << i
        print i, bin(j, N), bin(t[i], N)
    print

dT(T, 16)

def crc32_(crc, b):
    M = 0x04c11db7
    for i in xrange(8):
        f = (b & 0x80) << 24
        f = ((crc ^ f) & 0x80000000) and M or 0
        crc = ((crc << 1) ^ f) & 0xffffffff
        b = b << 1
    return crc

def crc32_(crc, b):
    M = 0x04c11db7
    #M = 0xe5
    crc ^= b << 24
    for i in xrange(8):
        f = (crc & 0x80000000) and M or 0
        crc = ((crc << 1) ^ f) & 0xffffffff
    return crc

T = [crc32_(0, 1 << i) for i in xrange(8)]

dT(T, 32)
for t in T:
    print "0x%08x" % t
print

def crc32_(crc, b):
    ndx   = (crc >> 24) ^ b
    crc <<= 8
    for i in xrange(8):
        if ndx & 1:
            crc ^= T[i]
        ndx >>= 1
    return crc & 0xffffffff

def crc(s, f=crc32_):
    r = 0
    for c in s:
        r = f(r, ord(c))
    return r

def swpb(w):
    w  = (w >> 8) | (w << 8)
    w &= 0xffff
    return w

U = [ ]
for t in T:
    U.append(t & 0xffff)
    U.append(t >> 16)
T = U
#del t, U
#for i in xrange(len(T)):
#    print ".word 0x%04x" % T[i]

def crc32_((h, l), b):
    # need 2 (byte) temps: ndx and t
    #
    h    = swpb(h)   # hl,hh   [1]
    ndx  = h & 0xff  # hh      [1] USE mov.b h,ndx -- crc>>24
    h   ^= ndx       # hl,0    [1]
    ndx ^= b         # ndx     [2] USE xor.b @ptr+, ndx
    l    = swpb(l)   # ll,lh   [1]
    t    = l & 0xff  # 0,lh    [1] USE mov.b l, t
    h   |= t         # hl,lh   [1]
    l   ^= t         # ll,0    [1] crc = hl,lh,ll,0 -- crc<<8
    t    = 0         #         [1]
    #                         <10>
    while t < 16:
        if ndx & 1:          # [3] bit+jz
            l ^= T[t]        # [3] USE xor #T(t), l
            h ^= T[t+1]      # [3] USE xor #T+2(t), h  OMIT for 0xe5
        t += 2               # [1] USE add #4, t
        ndx >>= 1            # [1]
    #                          <5/11>   [8]
    #                          <40/88>  [68]
    # avg 74 clk/byte -- ~19 us/byte, worst case: 98 clk, ~25 us/byte
    #
    # sub8 0xe5
    #  <5/8> [6.5] -> [52] -> [62] -> ~16 us/byte
    return (h, l)

def crc32_sub((h, l), b):
    # need 2 (byte) temps: ndx and t
    #
    h    = swpb(h)   # hl,hh   [1]
    ndx  = h & 0xff  # hh      [1] USE mov.b h,ndx -- crc>>24
    h   ^= ndx       # hl,0    [1]
    ndx ^= b         # ndx     [2] USE xor.b @ptr+, ndx
    l    = swpb(l)   # ll,lh   [1]
    t    = l & 0xff  # 0,lh    [1] USE mov.b l, t
    h   |= t         # hl,lh   [1]
    l   ^= t         # ll,0    [1] crc = hl,lh,ll,0 -- crc<<8
    #                          <9>
    l   ^= ndx       #         [1]
    ndx <<= 2        #         [2]
    l   ^= ndx       #         [1]
    ndx <<= 3        #         [3]
    l   ^= ndx       #         [1]
    ndx <<= 1        #         [1]
    l   ^= ndx       #         [1]
    ndx <<= 1        #         [1]
    l   ^= ndx       #         [1]
    #                         <21>
    return (h, l)

def crc(s, f=crc32_sub):
    r = (0, 0)
    for c in s:
        r = f(r, ord(c))
    return (r[0] << 16) | r[1]

print "0x%08x" % crc("hello")
assert crc("hello") == 0xb0604465, hex(crc("hello"))

