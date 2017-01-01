AUTOMAKE_OPTIONS = foreign

STOW_DIR=/opt
INC_DIR=$(STOW_DIR)/include
LIB_DIR=$(STOW_DIR)/lib

CFLAGS=-O0 -g -Wall -I../sf -I$(INC_DIR)

MIGFLAGS = -D_POSIX_C_SOURCE
TOS=$(shell ncc -print-tosdir)
SERIAL_H = $(TOS)/lib/serial/Serial.h

BUILT_SOURCES = serialpacket.h serialprotocol.h

bin_PROGRAMS=sf mnlisten mnsend
lib_LIBRARIES=libmotenet.a
include_HEADERS=am.h am_types.h motenet.h ../sf/message.h ../sf/serialsource.h ../sf/sfsource.h

sf_SOURCES = ../sf/sf.c
sf_LDADD = libmotenet.a $(LIB_DIR)/libnetlib.a

mnlisten_SOURCES = mnlisten.c
mnlisten_LDADD   = libmotenet.a $(LIB_DIR)/libnetlib.a

mnsend_SOURCES = mnsend.c
mnsend_LDADD   = libmotenet.a $(LIB_DIR)/libnetlib.a

libmotenet_a_SOURCES =       \
	serialpacket.c       \
	../sf/message.c      \
	../sf/serialsource.c \
	../sf/sfsource.c     \
	motenet.c

serialpacket.c serialpacket.h: $(SERIAL_H)
	mig -o serialpacket.h -c-prefix=spacket c $(SERIAL_H) serial_packet $(MIGFLAGS)

serialprotocol.h: $(SERIAL_H)
	ncg -o $@ -c-prefix=SERIAL c $(SERIAL_H) Serial.h $(MIGFLAGS)
